import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_portfolio/view/media_tool/video_editor/application/export_plan.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/video_editor_project.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProcessResult> _ff(List<String> args, {String? cwd}) =>
    Process.run('ffmpeg', ['-y', '-hide_banner', '-loglevel', 'error', ...args],
        workingDirectory: cwd);

void main() {
  late Directory tmp;
  late bool hasFfmpeg;

  setUpAll(() async {
    hasFfmpeg = (await Process.run('which', ['ffmpeg'])).exitCode == 0;
    tmp = await Directory.systemTemp.createTemp('export_plan_');
  });
  tearDownAll(() async => tmp.delete(recursive: true));

  Future<Uint8List> gen(String name, List<String> args) async {
    final r = await _ff([...args, name], cwd: tmp.path);
    expect(r.exitCode, 0, reason: r.stderr.toString());
    return File('${tmp.path}/$name').readAsBytes();
  }

  test('plan steps are valid FFmpeg and produce a playable file', () async {
    if (!hasFfmpeg) {
      markTestSkipped('ffmpeg not installed');
      return;
    }
    final withAudio = await gen('a.mp4', [
      '-f',
      'lavfi',
      '-i',
      'testsrc=size=640x360:rate=30:duration=4',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=440:duration=4',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-shortest',
    ]);
    final silent = await gen('b.mp4', [
      '-f',
      'lavfi',
      '-i',
      'testsrc2=size=320x240:rate=25:duration=3',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
    ]);
    final png = await gen('i.png', [
      '-f',
      'lavfi',
      '-i',
      'color=c=orange:s=200x100',
      '-frames:v',
      '1',
    ]);
    final overlayPng = await gen('o.png', [
      '-f',
      'lavfi',
      '-i',
      'color=c=red@0.5:s=360x640,format=rgba',
      '-frames:v',
      '1',
    ]);
    final fxVideo = await gen('fx.mp4', [
      '-f', 'lavfi', '-i', 'testsrc=size=160x90:rate=24:duration=1',
      '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
    ]);
    final music = await gen('m.mp3', [
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=220:duration=10',
    ]);

    EditorClip clip(String id, EditorAssetType t, Uint8List b, int ms,
            {EditorTransition tr = EditorTransition.fade,
            Duration trim = Duration.zero,
            double speed = 1,
            EditorFilter filter = const EditorFilter()}) =>
        EditorClip(
          id: id,
          name: id,
          type: t,
          bytes: b,
          duration: Duration(milliseconds: ms),
          transition: tr,
          trimStart: trim,
          speed: speed,
          filter: filter,
        );

    final project = VideoEditorProject(
      aspectRatio: 9 / 16,
      clips: [
        clip('c1', EditorAssetType.video, withAudio, 2500,
            trim: const Duration(seconds: 1),
            filter: const EditorFilter(preset: 'vivid', brightness: .1)),
        clip('c2', EditorAssetType.video, silent, 1500,
            tr: EditorTransition.slideLeft, speed: 2),
        clip('c3', EditorAssetType.image, png, 2000,
                tr: EditorTransition.circle)
            .copyWith(
                transition: EditorTransition.fx,
                fx: EditorFx(id: 'f', name: 'WebM', video: fxVideo)),
        clip('c4', EditorAssetType.image, png, 1500)
            .copyWith(
                transition: EditorTransition.fx,
                fx: const EditorFx(
                    id: 's',
                    name: 'Boom',
                    sprite: SpriteSpec(cols: 2, rows: 2))),
      ],
      overlays: [
        const EditorOverlay(
          id: 'o1',
          type: EditorOverlayType.text,
          label: 'Hi',
          start: Duration(seconds: 1),
          duration: Duration(seconds: 3),
        ),
        const EditorOverlay(
          id: 'o2',
          type: EditorOverlayType.particles,
          label: 'confetti',
          start: Duration.zero,
          duration: Duration(seconds: 2),
        ),
      ],
      audioTracks: [
        EditorAudioTrack(id: 'a1', name: 'm', bytes: music, volume: .5)
      ],
    );

    final plan = buildExportPlan(ExportRequest(
      project: project,
      shortSide: 360,
      imagePngs: {'c3': png, 'c4': png},
      sequences: {
        'o1': OverlaySequence([overlayPng], 20),
        'o2': OverlaySequence([for (var i = 0; i < 8; i++) overlayPng], 20),
        'fx:3': OverlaySequence([for (var i = 0; i < 17; i++) overlayPng], 20),
      },
      hasAudio: {'c1': true, 'c2': false},
    ));
    expect(plan.width, 360);
    expect(plan.height, 640);
    expect(plan.warnings, isEmpty);
    for (final step in plan.steps) {
      expect(step.args.join(' '), isNot(contains('lavfi')),
          reason: 'the wasm core has no lavfi input');
    }

    for (final e in plan.inputs.entries) {
      await File('${tmp.path}/${e.key}').writeAsBytes(e.value);
    }
    for (final step in plan.steps) {
      var r = await _ff(step.args, cwd: tmp.path);
      if (r.exitCode != 0 && step.fallbackArgs != null) {
        r = await _ff(step.fallbackArgs!, cwd: tmp.path);
      }
      expect(r.exitCode, 0,
          reason: '${step.label}\n${step.args.join(' ')}\n${r.stderr}');
    }
    final out = File('${tmp.path}/${plan.output}');
    expect(await out.exists(), isTrue);

    final probe = await Process.run('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'stream=codec_type,width,height',
      '-show_entries',
      'format=duration',
      '-of',
      'default=nw=1',
      out.path,
    ]);
    final text = probe.stdout.toString();
    expect(text, contains('codec_type=video'));
    expect(text, contains('codec_type=audio'));
    expect(text, contains('width=360'));
    expect(text, contains('height=640'));
    final dur =
        double.parse(RegExp(r'duration=([\d.]+)').firstMatch(text)!.group(1)!);
    // 2.5 + 1.5 + 2.0 + 1.5 = 7.5s timeline.
    expect(dur, closeTo(7.5, .6));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
