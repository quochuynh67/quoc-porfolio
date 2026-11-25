import 'dart:typed_data';

import '../domain/video_editor_project.dart';
import '../presentation/editor_visuals.dart' show filterMatrix;
import '../platform/video_source.dart' show sniffMime;

/// One FFmpeg invocation.
class ExportStep {
  const ExportStep(this.label, this.args, {this.fallbackArgs});
  final String label;
  final List<String> args;

  /// Tried when [args] fails (e.g. an xfade transition the core lacks).
  final List<String>? fallbackArgs;
}

class ExportPlan {
  ExportPlan({
    required this.inputs,
    required this.steps,
    required this.output,
    required this.warnings,
    required this.width,
    required this.height,
    required this.cleanup,
  });

  /// Files to write into the FFmpeg file system before running [steps].
  final Map<String, Uint8List> inputs;
  final List<ExportStep> steps;
  final String output;
  final List<String> warnings;
  final int width;
  final int height;

  /// Intermediate files to delete once the final file is built.
  final List<String> cleanup;
}

/// What the plan needs to know that only FFmpeg can tell us.
/// Pre-rendered transparent full-canvas frames of one overlay (or effect).
class OverlaySequence {
  const OverlaySequence(this.frames, this.fps);
  final List<Uint8List> frames;
  final int fps;
  bool get isStatic => frames.length == 1;
}

class ExportRequest {
  const ExportRequest({
    required this.project,
    required this.shortSide,
    required this.imagePngs,
    required this.sequences,
    this.hasAudio = const {},
    this.includeMusic = true,
  });

  final VideoEditorProject project;

  /// Output short side in pixels (480 / 720 / 1080).
  final int shortSide;

  /// Image clips re-encoded as PNG, by clip id.
  final Map<String, Uint8List> imagePngs;

  /// Overlay renders by overlay id; sprite-effect transitions use
  /// `fx:<clip index>`.
  final Map<String, OverlaySequence> sequences;

  /// Whether each video clip has an audio stream, by clip id.
  final Map<String, bool> hasAudio;
  final bool includeMusic;
}

const _fps = 30;

/// 16-bit mono 22.05 kHz silence. Used instead of the `lavfi` anullsrc
/// source, which the WebAssembly core does not ship.
Uint8List silenceWav(Duration length) {
  const rate = 22050;
  final samples = (length.inMicroseconds * rate / 1e6).ceil() + rate ~/ 2;
  final dataLen = samples * 2;
  final out = ByteData(44 + dataLen);
  void str(int o, String v) {
    for (var i = 0; i < v.length; i++) {
      out.setUint8(o + i, v.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  out.setUint32(4, 36 + dataLen, Endian.little);
  str(8, 'WAVEfmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little);
  out.setUint16(22, 1, Endian.little);
  out.setUint32(24, rate, Endian.little);
  out.setUint32(28, rate * 2, Endian.little);
  out.setUint16(32, 2, Endian.little);
  out.setUint16(34, 16, Endian.little);
  str(36, 'data');
  out.setUint32(40, dataLen, Endian.little);
  return out.buffer.asUint8List();
}

const _encode = [
  '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23', //
  '-pix_fmt', 'yuv420p', '-r', '$_fps',
  '-c:a', 'aac', '-b:a', '128k', '-ar', '44100', '-ac', '2',
];

String sec(Duration d) => (d.inMicroseconds / 1e6).toStringAsFixed(3);

/// File name used for the source of a video clip inside FFmpeg's FS.
String sourceName(EditorClip clip, int index) {
  final mime = sniffMime(clip.bytes);
  final ext = mime.contains('webm')
      ? 'webm'
      : mime.contains('quicktime')
          ? 'mov'
          : 'mp4';
  return 'src$index.$ext';
}

String audioName(EditorAudioTrack track, int index) {
  final mime = sniffMime(track.bytes, audio: true);
  final ext = mime.contains('webm')
      ? 'webm'
      : mime.contains('wav')
          ? 'wav'
          : mime.contains('mp4')
              ? 'm4a'
              : 'mp3';
  return 'aud$index.$ext';
}

(int, int) exportSize(double aspect, int shortSide) {
  int even(double v) => (v / 2).round() * 2;
  return aspect < 1
      ? (shortSide, even(shortSide / aspect))
      : (even(shortSide * aspect), shortSide);
}

/// Best-effort mapping from editor transitions to FFmpeg `xfade` names.
String xfadeFor(EditorTransition t) => switch (t) {
      EditorTransition.fade => 'fade',
      EditorTransition.dipBlack => 'fadeblack',
      EditorTransition.slideLeft => 'slideleft',
      EditorTransition.slideRight => 'slideright',
      EditorTransition.slideUp => 'slideup',
      EditorTransition.pushLeft => 'slideleft',
      EditorTransition.zoomIn => 'circleopen',
      EditorTransition.zoomOut => 'circleclose',
      EditorTransition.wipe => 'wipeleft',
      EditorTransition.spin => 'radial',
      EditorTransition.blur => 'dissolve',
      EditorTransition.flash => 'fadewhite',
      EditorTransition.glitch => 'pixelize',
      EditorTransition.circle => 'circleopen',
      EditorTransition.blinds => 'vertopen',
      EditorTransition.pixelate => 'pixelize',
      EditorTransition.fx => 'fadewhite',
      EditorTransition.none => 'fade',
    };

String _atempo(double speed) {
  final parts = <String>[];
  var s = speed;
  while (s > 2.0) {
    parts.add('atempo=2.0');
    s /= 2;
  }
  while (s < 0.5) {
    parts.add('atempo=0.5');
    s *= 2;
  }
  parts.add('atempo=${s.toStringAsFixed(4)}');
  return parts.join(',');
}

String _fmt(double v) => v.toStringAsFixed(4);

String? _colorFilter(EditorFilter f) {
  if (f.isIdentity) return null;
  final m = filterMatrix(f);
  final mix = 'colorchannelmixer='
      'rr=${_fmt(m[0])}:rg=${_fmt(m[1])}:rb=${_fmt(m[2])}:'
      'gr=${_fmt(m[5])}:gg=${_fmt(m[6])}:gb=${_fmt(m[7])}:'
      'br=${_fmt(m[10])}:bg=${_fmt(m[11])}:bb=${_fmt(m[12])}';
  final offset = ((m[4] + m[9] + m[14]) / 3 / 255).clamp(-1.0, 1.0);
  return offset.abs() < .005 ? mix : '$mix,eq=brightness=${_fmt(offset)}';
}

Duration transitionWindowFor(List<EditorClip> clips, int index) {
  if (index <= 0 || index >= clips.length) return Duration.zero;
  final clip = clips[index];
  final cap = Duration(microseconds: clip.duration.inMicroseconds ~/ 2);
  return clip.transitionDuration < cap ? clip.transitionDuration : cap;
}

ExportPlan buildExportPlan(ExportRequest r) {
  final project = r.project;
  final clips = project.clips;
  final (w, h) = exportSize(project.aspectRatio, r.shortSide);
  final inputs = <String, Uint8List>{};
  final steps = <ExportStep>[];
  final cleanup = <String>[];
  final warnings = <String>[];
  final parts = <String>[];

  final fit = project.fitContain
      ? 'scale=$w:$h:force_original_aspect_ratio=decrease,'
          'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:black'
      : 'scale=$w:$h:force_original_aspect_ratio=increase,crop=$w:$h';
  var longest = Duration.zero;
  for (final c in clips) {
    if (c.duration > longest) longest = c.duration;
  }
  inputs['silence.wav'] = silenceWav(longest);
  cleanup.add('silence.wav');

  // 1) Normalise every clip: size, fps, grade, speed, audio.
  for (var i = 0; i < clips.length; i++) {
    final c = clips[i];
    final out = 'c$i.mp4';
    final dur = sec(c.duration);
    final color = _colorFilter(c.filter);
    final vfParts = [
      if (c.type == EditorAssetType.video && c.speed != 1)
        'setpts=PTS/${c.speed.toStringAsFixed(4)}',
      fit,
      'setsar=1',
      'fps=$_fps',
      if (color != null) color,
      'format=yuv420p',
    ];
    final vf = vfParts.join(',');

    if (c.type == EditorAssetType.image) {
      final img = 'img$i.png';
      inputs[img] = r.imagePngs[c.id] ?? c.bytes;
      cleanup.add(img);
      steps.add(ExportStep('Clip ${i + 1}/${clips.length}', [
        '-loop', '1', '-framerate', '$_fps', '-t', dur, '-i', img, //
        '-i', 'silence.wav',
        '-vf', vf, '-map', '0:v', '-map', '1:a',
        ..._encode, '-t', dur, out,
      ]));
    } else {
      final src = sourceName(c, i);
      inputs[src] = c.bytes;
      cleanup.add(src);
      final audio = r.hasAudio[c.id] ?? false;
      final span = sec(Duration(
          microseconds: (c.duration.inMicroseconds * c.speed).round()));
      final af = audio
          ? [
              if (c.speed != 1) _atempo(c.speed),
              'volume=${c.volume.toStringAsFixed(3)}',
              'aresample=44100',
            ].join(',')
          : 'aresample=44100';
      steps.add(ExportStep('Clip ${i + 1}/${clips.length}', [
        '-ss', sec(c.trimStart), '-t', span, '-i', src, //
        if (!audio) ...['-i', 'silence.wav'],
        '-vf', vf, '-af', af,
        '-map', '0:v:0', '-map', audio ? '0:a:0' : '1:a:0',
        ..._encode, '-t', dur, out,
      ]));
    }
    cleanup.add(out);
  }

  // 2) Transitions: freeze the previous clip's last frame and xfade into the
  //    first moments of the incoming clip (mirrors the live preview).
  for (var i = 0; i < clips.length; i++) {
    final c = clips[i];
    final window = transitionWindowFor(clips, i);
    final wantsTransition = i > 0 &&
        c.transition != EditorTransition.none &&
        window > const Duration(milliseconds: 100);
    if (!wantsTransition) {
      parts.add('c$i.mp4');
      continue;
    }
    final prevDur = clips[i - 1].duration;
    final lastAt = prevDur > const Duration(milliseconds: 150)
        ? prevDur - const Duration(milliseconds: 100)
        : Duration.zero;
    final last = 'last$i.png';
    final tr = 't$i.mp4';
    final main = 'm$i.mp4';
    final win = sec(window);
    steps.add(ExportStep('Transition $i: grab frame', [
      '-ss',
      sec(lastAt),
      '-i',
      'c${i - 1}.mp4',
      '-frames:v',
      '1',
      last,
    ]));
    List<String> trArgs(String xf) => [
          '-loop', '1', '-framerate', '$_fps', '-t', win, '-i', last, //
          '-i', 'c$i.mp4',
          '-filter_complex',
          '[0:v]fps=$_fps,format=yuv420p,setsar=1[a];'
              '[1:v]trim=duration=$win,setpts=PTS-STARTPTS,fps=$_fps,'
              'format=yuv420p,setsar=1[b];'
              '[a][b]xfade=transition=$xf:duration=$win:offset=0[v];'
              '[1:a]atrim=duration=$win,asetpts=PTS-STARTPTS[aud]',
          '-map', '[v]', '-map', '[aud]', ..._encode, '-t', win, tr,
        ];
    steps.add(ExportStep(
      'Transition $i: ${c.transition.label}',
      trArgs(xfadeFor(c.transition)),
      fallbackArgs: trArgs('fade'),
    ));
    // Effect pack (sprite sheet frames or WebM/MP4) on top of the transition.
    var trFinal = tr;
    final fx = c.transition == EditorTransition.fx ? c.fx : null;
    if (fx != null) {
      final tf = 'tf$i.mp4';
      final seq = r.sequences['fx:$i'];
      if (fx.video != null) {
        final fxFile =
            'fx$i.${sniffMime(fx.video!).contains('webm') ? 'webm' : 'mp4'}';
        inputs[fxFile] = fx.video!;
        cleanup.add(fxFile);
        steps.add(ExportStep('Transition $i: effect', [
          '-i', tr, '-i', fxFile, //
          '-filter_complex',
          '[1:v]scale=$w:$h:force_original_aspect_ratio=increase,crop=$w:$h,'
              'fps=$_fps,format=yuv420p,setsar=1[f];'
              '[0:v]format=yuv420p[b];'
              '[b][f]blend=all_mode=screen[v]',
          '-map', '[v]', '-map', '0:a', ..._encode, '-t', win, tf,
        ]));
        trFinal = tf;
        cleanup.add(tf);
      } else if (seq != null) {
        final prefix = 'fx${i}_';
        for (var k = 0; k < seq.frames.length; k++) {
          inputs['$prefix${k.toString().padLeft(4, '0')}.png'] = seq.frames[k];
          cleanup.add('$prefix${k.toString().padLeft(4, '0')}.png');
        }
        steps.add(ExportStep('Transition $i: effect', [
          '-i', tr, '-framerate', '${seq.fps}', '-i', '$prefix%04d.png', //
          '-filter_complex',
          '[1:v]format=rgba,setpts=PTS-STARTPTS[f];'
              '[0:v][f]overlay=0:0:eof_action=pass:format=auto[v]',
          '-map', '[v]', '-map', '0:a', ..._encode, '-t', win, tf,
        ]));
        trFinal = tf;
        cleanup.add(tf);
      }
    }
    final rest = c.duration - window;
    parts.add(trFinal);
    if (rest > const Duration(milliseconds: 80)) {
      steps.add(ExportStep('Transition $i: remainder', [
        '-ss', win, '-i', 'c$i.mp4', ..._encode, '-t', sec(rest), main, //
      ]));
      parts.add(main);
      cleanup.add(main);
    }
    cleanup
      ..add(last)
      ..add(tr);
  }

  // 3) Join.
  inputs['list.txt'] =
      Uint8List.fromList(parts.map((p) => "file '$p'\n").join().codeUnits);
  steps.add(const ExportStep('Joining clips', [
    '-f',
    'concat',
    '-safe',
    '0',
    '-i',
    'list.txt',
    '-c',
    'copy',
    'joined.mp4',
  ]));
  cleanup
    ..add('joined.mp4')
    ..add('list.txt');

  // 4) Overlays + music in one pass.
  final total = project.duration;
  final overlays = <EditorOverlay>[];
  for (final o in project.overlays) {
    if (r.sequences.containsKey(o.id)) {
      overlays.add(o);
    } else {
      warnings.add('${_overlayName(o)} "${o.label}" could not be rendered '
          'and was skipped.');
    }
  }
  final tracks =
      r.includeMusic ? project.audioTracks : const <EditorAudioTrack>[];

  const output = 'vlog.mp4';
  if (overlays.isEmpty && tracks.isEmpty) {
    steps.add(const ExportStep('Finishing',
        ['-i', 'joined.mp4', '-c', 'copy', '-movflags', '+faststart', output]));
  } else {
    final args = <String>['-i', 'joined.mp4'];
    final graph = <String>[];
    var inputIndex = 1;
    var videoLabel = '0:v';
    for (var k = 0; k < overlays.length; k++) {
      final o = overlays[k];
      final seq = r.sequences[o.id]!;
      final next = 'v$k';
      final window = "enable='between(t,${sec(o.start)},${sec(o.end)})'";
      if (seq.isStatic) {
        final file = 'ov$k.png';
        inputs[file] = seq.frames.first;
        cleanup.add(file);
        args.addAll([
          '-loop',
          '1',
          '-framerate',
          '$_fps',
          '-t',
          sec(total),
          '-i',
          file
        ]);
        graph.add('[$videoLabel][$inputIndex:v]overlay=0:0:$window:'
            'format=auto[$next]');
      } else {
        for (var n = 0; n < seq.frames.length; n++) {
          final name = 'ov${k}_${n.toString().padLeft(4, '0')}.png';
          inputs[name] = seq.frames[n];
          cleanup.add(name);
        }
        args.addAll(['-framerate', '${seq.fps}', '-i', 'ov${k}_%04d.png']);
        graph.add('[$inputIndex:v]format=rgba,'
            'setpts=PTS-STARTPTS+${sec(o.start)}/TB[s$k];'
            '[$videoLabel][s$k]overlay=0:0:eof_action=pass:$window:'
            'format=auto[$next]');
      }
      videoLabel = next;
      inputIndex++;
    }
    var audioLabel = '0:a';
    if (tracks.isNotEmpty) {
      final mix = <String>['[0:a]volume=1[a0]'];
      for (var a = 0; a < tracks.length; a++) {
        final file = audioName(tracks[a], a);
        inputs[file] = tracks[a].bytes;
        cleanup.add(file);
        args.addAll(['-i', file]);
        mix.add('[$inputIndex:a]atrim=duration=${sec(total)},'
            'asetpts=PTS-STARTPTS,volume=${tracks[a].volume.toStringAsFixed(3)}[m$a]');
        inputIndex++;
      }
      final labels = ['[a0]', for (var a = 0; a < tracks.length; a++) '[m$a]'];
      mix.add('${labels.join()}amix=inputs=${labels.length}:duration=first:'
          'dropout_transition=0,volume=1.5[aout]');
      graph.addAll(mix);
      audioLabel = '[aout]';
    }
    if (graph.isNotEmpty) args.addAll(['-filter_complex', graph.join(';')]);
    args.addAll([
      '-map', overlays.isEmpty ? '0:v' : '[$videoLabel]',
      '-map', audioLabel,
      '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23', //
      '-pix_fmt', 'yuv420p', '-r', '$_fps',
      if (tracks.isEmpty) ...[
        '-c:a',
        'copy'
      ] else ...[
        '-c:a',
        'aac',
        '-b:a',
        '160k'
      ],
      '-movflags', '+faststart', '-t', sec(total), output,
    ]);
    steps.add(ExportStep('Overlays & music', args));
  }

  return ExportPlan(
    inputs: inputs,
    steps: steps,
    output: output,
    warnings: warnings,
    width: w,
    height: h,
    cleanup: cleanup,
  );
}

String _overlayName(EditorOverlay o) => switch (o.type) {
      EditorOverlayType.text => 'Text',
      EditorOverlayType.sticker => 'Sticker',
      EditorOverlayType.sprite => 'Sprite',
      EditorOverlayType.particles => 'Particles',
      EditorOverlayType.video => 'Video overlay',
    };
