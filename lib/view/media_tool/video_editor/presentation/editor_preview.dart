import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../screen/widget/media_ui.dart';
import '../application/export_plan.dart';
import '../application/video_editor_controller.dart';
import '../domain/editor_catalog.dart';
import '../domain/shader_catalog.dart';
import '../domain/video_editor_project.dart';
import '../platform/video_source.dart';
import 'editor_transitions.dart';
import 'editor_visuals.dart';
import 'overlay_layer.dart';

String formatTime(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Realtime canvas. Video frames are pulled into the Flutter canvas so
/// colour grading, transitions, blends and overlays all apply to real video.
class EditorPreview extends StatefulWidget {
  const EditorPreview({super.key, required this.controller});
  final VideoEditorController controller;

  @override
  State<EditorPreview> createState() => _EditorPreviewState();
}

class _EditorPreviewState extends State<EditorPreview> {
  final Map<String, VideoSource> _sources = {};
  final Map<String, ui.Image> _frames = {};
  final Set<String> _opening = {};
  final Set<String> _failed = {};
  bool _syncing = false;
  bool _syncAgain = false;

  VideoEditorController get _editor => widget.controller;

  @override
  void initState() {
    super.initState();
    _editor.frameListenable.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _editor.frameListenable.removeListener(_sync);
    for (final s in _sources.values) {
      s.dispose();
    }
    for (final f in _frames.values) {
      f.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------- sources

  Future<void> _open(String key, Uint8List bytes,
      {bool video = true, String? clipId}) async {
    if (_sources.containsKey(key) ||
        _opening.contains(key) ||
        _failed.contains(key)) {
      return;
    }
    _opening.add(key);
    final source = VideoSource.create(bytes, hasVideo: video);
    try {
      await source.init();
      if (!mounted) {
        source.dispose();
        return;
      }
      _sources[key] = source;
      if (clipId != null) _editor.setSourceDuration(clipId, source.duration);
    } catch (_) {
      source.dispose();
      _failed.add(key);
    } finally {
      _opening.remove(key);
      if (mounted) {
        setState(() {});
        _sync();
      }
    }
  }

  void _drop(String key) {
    _sources.remove(key)?.dispose();
    _frames.remove(key)?.dispose();
    _failed.remove(key);
  }

  Future<void> _sync() async {
    if (!mounted) return;
    if (_syncing) {
      // A state change (e.g. playback reaching the end) arrived mid-sync:
      // run again so the latest state is never lost.
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        await _syncInner();
      } while (_syncAgain && mounted);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncInner() async {
    final project = _editor.project;
    final playing = _editor.isPlaying;
    final position = _editor.position;
    final active = _editor.activeClip;
    final transition = _editor.activeTransition;

    // What should exist right now.
    final wanted = <String>{};
    final clipKeys = <String, EditorClip>{};
    void wantClip(EditorClip? clip) {
      if (clip == null || clip.type != EditorAssetType.video) return;
      final key = 'clip:${clip.id}';
      wanted.add(key);
      clipKeys[key] = clip;
      _open(key, clip.bytes, clipId: clip.id);
    }

    wantClip(active);
    wantClip(transition?.outgoing);

    final overlayKeys = <String, EditorOverlay>{};
    for (final o in project.overlays) {
      if (o.type != EditorOverlayType.video || o.video == null) continue;
      final key = 'ov:${o.id}';
      overlayKeys[key] = o;
      if (position >= o.start && position <= o.end) {
        wanted.add(key);
        _open(key, o.video!);
      }
    }

    final fx = transition?.incoming.fx;
    if (fx?.video != null && transition != null) {
      wanted.add('fx:${fx!.id}');
      _open('fx:${fx.id}', fx.video!);
    }

    for (final track in project.audioTracks) {
      final key = 'audio:${track.id}';
      wanted.add(key);
      _open(key, track.bytes, video: false);
    }

    // Dispose sources that are gone from the project.
    final valid = <String>{
      for (final c in project.clips) 'clip:${c.id}',
      for (final o in project.overlays) 'ov:${o.id}',
      for (final t in project.audioTracks) 'audio:${t.id}',
      for (final c in project.clips)
        if (c.fx != null) 'fx:${c.fx!.id}',
    };
    for (final key in _sources.keys.toList()) {
      if (!valid.contains(key)) _drop(key);
    }

    var changed = false;
    for (final entry in _sources.entries.toList()) {
      final key = entry.key;
      final source = entry.value;
      if (!source.ready) continue;

      if (key.startsWith('clip:')) {
        final clip = clipKeys[key];
        if (clip == null) {
          source.pause();
          continue;
        }
        if (clip.id == active?.id) {
          final local = _editor.activeClipPosition;
          final target = transition == null
              ? clip.trimStart +
                  Duration(
                    microseconds: (local.inMicroseconds * clip.speed).round(),
                  )
              : transitionFrameTimes(
                  transition.outgoing,
                  transition.incoming,
                  _editor.transitionWindow(_editor.activeClipIndex),
                  transition.progress,
                ).incoming;
          source.setVolume(clip.volume * (transition?.progress ?? 1));
          source.setSpeed(clip.speed);
          final drift = (source.position - target).inMilliseconds.abs();
          if (playing) {
            if (drift > 400) source.seek(target);
            source.play();
          } else {
            source.pause();
            if (drift > 40) source.seek(target);
          }
        } else if (transition != null && clip.id == transition.outgoing.id) {
          final target = transitionFrameTimes(
            transition.outgoing,
            transition.incoming,
            _editor.transitionWindow(_editor.activeClipIndex),
            transition.progress,
          ).outgoing;
          source.setVolume(clip.volume * (1 - transition.progress));
          source.setSpeed(clip.speed);
          final drift = (source.position - target).inMilliseconds.abs();
          if (playing) {
            if (drift > 120) source.seek(target);
            source.play();
          } else {
            source.pause();
            if (drift > 20) source.seek(target);
          }
        } else {
          source.pause();
        }
      } else if (key.startsWith('audio:')) {
        final id = key.substring(6);
        final track = project.audioTracks.where((t) => t.id == id).firstOrNull;
        if (track == null) continue;
        source.setVolume(track.volume);
        // Music never outlives the video: stop at the end of the last clip.
        final inRange =
            position < source.duration && position < project.duration;
        if (playing && inRange) {
          if ((source.position - position).inMilliseconds.abs() > 350) {
            source.seek(position);
          }
          source.play();
        } else {
          source.pause();
          if (inRange &&
              (source.position - position).inMilliseconds.abs() > 80) {
            source.seek(position);
          }
        }
      } else if (key.startsWith('ov:')) {
        final o = overlayKeys[key];
        if (o == null || !wanted.contains(key)) {
          source.pause();
          continue;
        }
        source.setVolume(0);
        final dur = source.duration.inMicroseconds;
        final local = position - o.start;
        final target = dur == 0
            ? Duration.zero
            : Duration(microseconds: local.inMicroseconds % dur);
        if (playing) {
          if ((source.position - target).inMilliseconds.abs() > 400) {
            source.seek(target);
          }
          source.play();
        } else {
          source.pause();
          if ((source.position - target).inMilliseconds.abs() > 60) {
            source.seek(target);
          }
        }
      } else if (key.startsWith('fx:')) {
        if (transition == null || fx == null || key != 'fx:${fx.id}') {
          source.pause();
          continue;
        }
        source.setVolume(0);
        final window = _editor.transitionWindow(_editor.activeClipIndex);
        final target = Duration(
            microseconds:
                (window.inMicroseconds * transition.progress).round());
        if (playing) {
          if ((source.position - target).inMilliseconds.abs() > 300) {
            source.seek(target);
          }
          source.play();
        } else {
          source.pause();
          source.seek(target);
        }
      }

      if (wanted.contains(key) && !key.startsWith('audio:')) {
        final image = await source.grabFrame();
        if (image != null) {
          _frames[key]?.dispose();
          _frames[key] = image;
          changed = true;
        }
      }
    }
    if (changed && mounted) setState(() {});
  }

  // ---------------------------------------------------------------- layers

  Widget _frameView(String key, BoxFit fit) {
    final image = _frames[key];
    if (image == null) return const SizedBox.shrink();
    return RawImage(
        image: image, fit: fit, filterQuality: FilterQuality.medium);
  }

  Widget _clipLayer(EditorClip clip) {
    final contain = _editor.project.fitContain;
    final fit = contain ? BoxFit.contain : BoxFit.cover;
    if (clip.type == EditorAssetType.image) {
      return ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(child: ClipVisual(clip: clip, fit: fit)),
      );
    }
    final key = 'clip:${clip.id}';
    if (_failed.contains(key)) return const _DecodeError();
    if (_frames[key] == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: FilteredClip(
        filter: clip.filter,
        child: SizedBox.expand(child: _frameView(key, fit)),
      ),
    );
  }

  Widget? _fxOverlay(ActiveTransition t) {
    final fx = t.incoming.fx;
    if (t.type != EditorTransition.fx || fx == null) return null;
    final fade = (1 - (2 * t.progress - 1).abs()).clamp(0.0, 1.0) * 1.4;
    if (fx.sprite != null) {
      final spec = fx.sprite!;
      return IgnorePointer(
        child: Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: SpriteView(
            spec: spec,
            time: Duration(
                microseconds:
                    (spec.loopDuration.inMicroseconds * t.progress).round()),
          ),
        ),
      );
    }
    if (fx.video != null) {
      return IgnorePointer(
        child: BlendBox(
          blendMode: BlendMode.screen,
          child:
              SizedBox.expand(child: _frameView('fx:${fx.id}', BoxFit.cover)),
        ),
      );
    }
    return null;
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _editor.frameListenable,
      builder: (context, _) {
        final active = _editor.activeClip;
        final transition = _editor.activeTransition;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C0F18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mediaPanelBorder),
          ),
          child: Column(
            children: [
              _CanvasBar(controller: _editor),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ratio = _editor.project.aspectRatio;
                    final maxW = (constraints.maxWidth - 24).clamp(1.0, 4000.0);
                    final maxH =
                        (constraints.maxHeight - 12).clamp(1.0, 4000.0);
                    var width = maxW;
                    var height = width / ratio;
                    if (height > maxH) {
                      height = maxH;
                      width = height * ratio;
                    }
                    return Center(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _Canvas(
                            editor: _editor,
                            frameFor: (key) => _frames[key],
                            base: active == null
                                ? const _EmptyCanvas()
                                : transition == null
                                    ? _clipLayer(active)
                                    : buildTransitionFrame(
                                        type: transition.type,
                                        shaderId: transition.shaderId,
                                        t: transition.progress,
                                        outgoing:
                                            _clipLayer(transition.outgoing),
                                        incoming:
                                            _clipLayer(transition.incoming),
                                        fxOverlay: _fxOverlay(transition),
                                      ),
                            transitionLabel: transition == null
                                ? null
                                : transition.type == EditorTransition.fx
                                    ? transition.incoming.fx?.name ?? 'FX'
                                    : transition.type.isShader
                                        ? shaderById(transition.shaderId)
                                                ?.name ??
                                            'Shader'
                                        : transition.type.label,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              PlaybackControls(controller: _editor),
            ],
          ),
        );
      },
    );
  }
}

/// Aspect-ratio selector + fit toggle above the canvas.
class _CanvasBar extends StatelessWidget {
  const _CanvasBar({required this.controller});
  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    final project = controller.project;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                for (final (label, ratio) in aspectPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      selected: (project.aspectRatio - ratio).abs() < .01,
                      onSelected: (_) => controller.updateAspectRatio(ratio),
                    ),
                  ),
              ],
            ),
          ),
          Tooltip(
            message: project.fitContain
                ? 'Fit: show whole frame'
                : 'Fill: crop to canvas',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.setFitContain(!project.fitContain),
              icon: Icon(
                project.fitContain
                    ? Icons.fit_screen_rounded
                    : Icons.crop_free_rounded,
                size: 20,
                color: project.fitContain ? Colors.cyanAccent : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.editor,
    required this.base,
    required this.frameFor,
    this.transitionLabel,
  });

  final VideoEditorController editor;
  final Widget base;
  final ui.Image? Function(String key) frameFor;
  final String? transitionLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Overlay sizes scale with the canvas so previews match export size.
        final scale = (box.maxWidth / 360).clamp(.5, 2.5);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            base,
            for (final overlay in editor.activeOverlays)
              _OverlayItem(
                editor: editor,
                overlay: overlay,
                canvas: box.biggest,
                scale: scale,
                frameFor: frameFor,
              ),
            if (transitionLabel != null)
              Positioned(
                top: 10,
                right: 10,
                child: _Badge(
                    icon: Icons.auto_awesome_rounded, text: transitionLabel!),
              ),
            const Positioned(
              top: 10,
              left: 10,
              child: _Badge(icon: Icons.circle, text: 'Live', dot: true),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayItem extends StatelessWidget {
  const _OverlayItem({
    required this.editor,
    required this.overlay,
    required this.canvas,
    required this.scale,
    required this.frameFor,
  });

  final VideoEditorController editor;
  final EditorOverlay overlay;
  final Size canvas;
  final double scale;
  final ui.Image? Function(String key) frameFor;

  @override
  Widget build(BuildContext context) {
    return OverlayLayer(
      overlay: overlay,
      canvas: canvas,
      unit: scale,
      position: editor.position,
      playing: editor.isPlaying,
      selected: editor.selectedOverlayId == overlay.id,
      videoFrame: overlay.type == EditorOverlayType.video
          ? frameFor('ov:${overlay.id}')
          : null,
      onTap: () => editor.selectOverlay(overlay.id),
      onDrag: (delta) => editor.updateSelectedOverlay(
        position: Offset(
          (overlay.position.dx + delta.dx / canvas.width).clamp(.02, .98),
          (overlay.position.dy + delta.dy / canvas.height).clamp(.02, .98),
        ),
      ),
    );
  }
}

class _EmptyCanvas extends StatelessWidget {
  const _EmptyCanvas();
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.movie_creation_outlined,
                  color: Colors.white24, size: 48),
              SizedBox(height: 8),
              Text('Import a video or image\nto start editing',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecodeError extends StatelessWidget {
  const _DecodeError();
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.orangeAccent),
              SizedBox(height: 8),
              Text('This browser cannot decode the video.\nTry MP4 (H.264).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, this.dot = false});
  final IconData icon;
  final String text;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: dot ? 7 : 11,
              color: dot ? Colors.greenAccent : Colors.amberAccent),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key, required this.controller});
  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Back to start',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.seek(Duration.zero),
            icon: const Icon(Icons.skip_previous_rounded),
          ),
          IconButton.filled(
            tooltip: controller.isPlaying ? 'Pause' : 'Play',
            onPressed: controller.togglePlayback,
            icon: Icon(controller.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded),
          ),
          IconButton(
            tooltip: 'Go to end',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.seek(controller.project.duration),
            icon: const Icon(Icons.skip_next_rounded),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatTime(controller.position)} / '
            '${formatTime(controller.project.duration)}',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFeatures: [ui.FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}
