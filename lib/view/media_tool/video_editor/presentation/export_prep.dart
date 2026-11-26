import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../application/export_plan.dart';
import '../domain/video_editor_project.dart';
import '../platform/video_source.dart';
import 'editor_visuals.dart';
import 'overlay_layer.dart';

typedef RenderProgress = void Function(String label, double fraction);

/// Frame rate of animated overlay renders (the video itself is 30 fps).
const overlayFps = 20;
const _maxFrames = 400;

/// Re-encodes any decodable image as PNG (FFmpeg-friendly).
Future<Uint8List> imageToPng(Uint8List bytes) async {
  final image = await decodeImageFromList(bytes);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

bool _isAnimated(EditorOverlay o) =>
    o.type == EditorOverlayType.sprite ||
    o.type == EditorOverlayType.particles ||
    o.type == EditorOverlayType.video ||
    o.enter != OverlayEnter.none ||
    o.exit != OverlayExit.none ||
    o.loop != OverlayLoop.none;

int _frameCount(Duration length) =>
    (length.inMilliseconds * overlayFps / 1000).ceil().clamp(2, _maxFrames) + 1;

/// Renders every overlay (text, stickers, sprites, particles, video overlays)
/// and sprite-effect transitions to transparent, full-canvas PNG frames at the
/// export resolution, using the same widgets as the live preview.
Future<Map<String, OverlaySequence>> renderSequences(
  BuildContext context,
  VideoEditorProject project,
  int shortSide, {
  required RenderProgress onProgress,
  required bool Function() isCancelled,
}) async {
  final (outW, outH) = exportSize(project.aspectRatio, shortSide);
  const pixelRatio = 2.0;
  final canvas = Size(outW / pixelRatio, outH / pixelRatio);
  final unit = (canvas.width / 360).clamp(.5, 2.5).toDouble();

  // Work list so progress is meaningful.
  final jobs = <_Job>[];
  for (final o in project.overlays) {
    jobs.add(_Job.overlay(o, _isAnimated(o) ? _frameCount(o.duration) : 1));
  }
  final clips = project.clips;
  for (var i = 1; i < clips.length; i++) {
    final c = clips[i];
    if (c.transition == EditorTransition.fx && c.fx?.sprite != null) {
      final window = transitionWindowFor(clips, i);
      if (window > Duration.zero) {
        jobs.add(_Job.fx(i, c.fx!.sprite!, window, _frameCount(window)));
      }
    }
  }
  final totalFrames = jobs.fold<int>(0, (a, j) => a + j.frames);
  if (totalFrames == 0) return {};

  final content = ValueNotifier<Widget>(const SizedBox());
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -canvas.width * 2 - 40,
      top: 0,
      width: canvas.width,
      height: canvas.height,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: key,
          child: ValueListenableBuilder<Widget>(
            valueListenable: content,
            builder: (_, w, __) => SizedBox(
              width: canvas.width,
              height: canvas.height,
              child: Stack(clipBehavior: Clip.hardEdge, children: [w]),
            ),
          ),
        ),
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);

  Future<Uint8List> capture({bool settle = false}) async {
    await WidgetsBinding.instance.endOfFrame;
    if (settle) {
      // Fonts and network images need a moment on the first frame.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await WidgetsBinding.instance.endOfFrame;
    }
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  final result = <String, OverlaySequence>{};
  var done = 0;
  void tick(String label) {
    onProgress(label, totalFrames == 0 ? 0 : done / totalFrames);
  }

  try {
    for (final job in jobs) {
      if (isCancelled()) break;
      final frames = <Uint8List>[];

      if (job.fxSprite != null) {
        final spec = job.fxSprite!;
        await SpriteImageCache.load(spec);
        for (var k = 0; k < job.frames; k++) {
          if (isCancelled()) break;
          final p = job.frames <= 1 ? 0.0 : k / (job.frames - 1);
          final envelope = (1 - (2 * p - 1).abs()).clamp(0.0, 1.0) * 1.4;
          content.value = Positioned.fill(
            child: Opacity(
              opacity: envelope.clamp(0.0, 1.0),
              child: SpriteView(
                spec: spec,
                time: Duration(
                    microseconds:
                        (spec.loopDuration.inMicroseconds * p).round()),
              ),
            ),
          );
          frames.add(await capture(settle: k == 0));
          done++;
          if (k % 4 == 0) tick('Rendering transition effect ${job.index}');
        }
        result['fx:${job.index}'] = OverlaySequence(frames, overlayFps);
        continue;
      }

      final o = job.overlay!;
      final label = '${o.type.name} "${o.label}"';
      if (o.type == EditorOverlayType.sprite && o.sprite != null) {
        await SpriteImageCache.load(o.sprite!);
      }

      VideoSource? source;
      if (o.type == EditorOverlayType.video && o.video != null) {
        source = VideoSource.create(o.video!);
        try {
          await source.init();
        } catch (_) {
          source.dispose();
          source = null;
          done += job.frames;
          continue; // skipped; the plan reports it
        }
      }

      for (var k = 0; k < job.frames; k++) {
        if (isCancelled()) break;
        final animated = job.frames > 1;
        final position = animated
            ? o.start + Duration(microseconds: k * 1000000 ~/ overlayFps)
            : o.start;
        ui.Image? frame;
        if (source != null) {
          final dur = source.duration.inMicroseconds;
          final local = (position - o.start).inMicroseconds;
          await source
              .seekTo(Duration(microseconds: dur == 0 ? 0 : local % dur));
          frame = await source.grabFrame(force: true);
        }
        content.value = OverlayLayer(
          overlay: o,
          canvas: canvas,
          unit: unit,
          position: position,
          playing: animated,
          videoFrame: frame,
          staticSticker: true,
        );
        frames.add(await capture(settle: k == 0));
        frame?.dispose();
        done++;
        if (k % 4 == 0) tick('Rendering $label');
      }
      source?.dispose();
      if (frames.isNotEmpty && !isCancelled()) {
        result[o.id] = OverlaySequence(frames, overlayFps);
      }
    }
  } finally {
    entry.remove();
    content.dispose();
  }
  return result;
}

class _Job {
  _Job.overlay(EditorOverlay this.overlay, this.frames)
      : fxSprite = null,
        index = 0,
        window = Duration.zero;
  _Job.fx(this.index, SpriteSpec this.fxSprite, this.window, this.frames)
      : overlay = null;

  final EditorOverlay? overlay;
  final SpriteSpec? fxSprite;
  final int index;
  final Duration window;
  final int frames;
}
