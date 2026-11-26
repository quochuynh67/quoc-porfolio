import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../screen/widget/media_ui.dart';
import '../application/video_editor_controller.dart';
import '../domain/video_editor_project.dart';
import 'editor_visuals.dart';

const _labelWidth = 64.0;
const _rulerHeight = 24.0;
const _videoHeight = 56.0;
const _overlayHeight = 30.0;
const _audioHeight = 34.0;
const _gap = 6.0;

/// Proportional multi-track timeline: widths and offsets follow real time.
class EditorTimeline extends StatefulWidget {
  const EditorTimeline({
    super.key,
    required this.controller,
    required this.onTransitionTap,
  });

  final VideoEditorController controller;

  /// Called when a transition marker between two clips is tapped.
  final VoidCallback onTransitionTap;

  @override
  State<EditorTimeline> createState() => _EditorTimelineState();
}

class _EditorTimelineState extends State<EditorTimeline> {
  double _zoom = 1; // 1 => 48 px per second
  final ScrollController _scroll = ScrollController();
  String? _lastRevealed;

  /// Scrolls the track so the selected clip / overlay is on screen.
  void _reveal(double viewport) {
    final clipId = _editor.selectedClipId;
    final overlayId = _editor.selectedOverlayId;
    final key = clipId ?? overlayId;
    if (key == _lastRevealed) return;
    _lastRevealed = key;
    if (key == null) return;
    Duration? start;
    Duration? length;
    if (clipId != null) {
      final i = _editor.project.clips.indexWhere((c) => c.id == clipId);
      if (i < 0) return;
      start = _editor.clipStart(i);
      length = _editor.project.clips[i].duration;
    } else {
      final o = _editor.selectedOverlay;
      if (o == null) return;
      start = o.start;
      length = o.duration;
    }
    final left = start.inMilliseconds / 1000 * _pps;
    final right = left + length.inMilliseconds / 1000 * _pps;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final offset = _scroll.offset;
      double? target;
      if (left < offset) {
        target = left - 20;
      } else if (right > offset + viewport) {
        target = math.min(left - 20, right - viewport + 20);
      }
      if (target != null) {
        _scroll.animateTo(
          target.clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  VideoEditorController get _editor => widget.controller;

  double get _pps => 48 * _zoom;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _editor.frameListenable,
      builder: (context, _) {
        final project = _editor.project;
        final selectedAny =
            _editor.selectedClip != null || _editor.selectedOverlay != null;
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          decoration: BoxDecoration(
            color: mediaPanelColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mediaPanelBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Split at playhead',
                    visualDensity: VisualDensity.compact,
                    onPressed: _editor.selectedClip == null
                        ? null
                        : _editor.splitSelectedClip,
                    icon: const Icon(Icons.content_cut_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Delete selection',
                    visualDensity: VisualDensity.compact,
                    onPressed: selectedAny ? _editor.removeSelection : null,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                  const Spacer(),
                  const Icon(Icons.zoom_out_rounded,
                      size: 16, color: Colors.white54),
                  SizedBox(
                    width: 110,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _zoom,
                        min: .4,
                        max: 3,
                        onChanged: (value) => setState(() => _zoom = value),
                      ),
                    ),
                  ),
                  const Icon(Icons.zoom_in_rounded,
                      size: 16, color: Colors.white54),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final available = box.maxWidth - _labelWidth;
                    final seconds = project.duration.inMilliseconds / 1000;
                    final contentWidth =
                        math.max(available, seconds * _pps + 60);
                    _reveal(available);
                    return SingleChildScrollView(
                        child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TrackLabels(),
                        SizedBox(
                          width: available,
                          // Mouse wheel scrolls the tracks sideways and a mouse
                          // can drag empty space to pan.
                          child: Listener(
                            onPointerSignal: (event) {
                              if (event is! PointerScrollEvent ||
                                  !_scroll.hasClients) {
                                return;
                              }
                              GestureBinding.instance.pointerSignalResolver
                                  .register(event, (e) {
                                final ev = e as PointerScrollEvent;
                                final d = ev.scrollDelta.dx != 0
                                    ? ev.scrollDelta.dx
                                    : ev.scrollDelta.dy;
                                _scroll.jumpTo((_scroll.offset + d).clamp(
                                    0.0, _scroll.position.maxScrollExtent));
                              });
                            },
                            child: ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.stylus,
                                  PointerDeviceKind.trackpad,
                                },
                              ),
                              child: SingleChildScrollView(
                                controller: _scroll,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: contentWidth,
                                  child: _TrackArea(
                                    editor: _editor,
                                    pps: _pps,
                                    width: contentWidth,
                                    onTransitionTap: widget.onTransitionTap,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackLabels extends StatelessWidget {
  const _TrackLabels();

  Widget _label(IconData icon, String text, double height) => SizedBox(
        height: height,
        width: _labelWidth,
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _labelWidth,
      child: Column(
        children: [
          const SizedBox(height: _rulerHeight + _gap),
          _label(Icons.videocam_outlined, 'Video', _videoHeight),
          const SizedBox(height: _gap),
          _label(Icons.title_rounded, 'Text', _overlayHeight),
          const SizedBox(height: _gap),
          _label(Icons.emoji_emotions_outlined, 'Sticker', _overlayHeight),
          const SizedBox(height: _gap),
          _label(Icons.music_note_rounded, 'Music', _audioHeight),
        ],
      ),
    );
  }
}

class _TrackArea extends StatelessWidget {
  const _TrackArea({
    required this.editor,
    required this.pps,
    required this.width,
    required this.onTransitionTap,
  });

  final VideoEditorController editor;
  final double pps;
  final double width;
  final VoidCallback onTransitionTap;

  double _x(Duration d) => d.inMilliseconds / 1000 * pps;

  void _scrub(double dx) {
    editor.seek(Duration(milliseconds: (dx / pps * 1000).round()));
  }

  @override
  Widget build(BuildContext context) {
    final project = editor.project;
    const videoTop = _rulerHeight + _gap;
    const textTop = videoTop + _videoHeight + _gap;
    const stickerTop = textTop + _overlayHeight + _gap;
    const audioTop = stickerTop + _overlayHeight + _gap;
    const totalHeight = audioTop + _audioHeight;
    final total = project.duration;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ruler doubles as the scrub area.
          Positioned(
            left: 0,
            top: 0,
            width: width,
            height: _rulerHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _scrub(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => _scrub(d.localPosition.dx),
              child: CustomPaint(painter: _RulerPainter(pps: pps)),
            ),
          ),
          // Video track
          Positioned(
            left: 0,
            top: videoTop,
            width: width,
            height: _videoHeight,
            child: project.clips.isEmpty
                ? const _EmptyTrack(label: 'Add video or images to begin')
                : const SizedBox.shrink(),
          ),
          // The selected clip paints last so a dragged block stays on top.
          for (final i in [
            for (var k = 0; k < project.clips.length; k++)
              if (project.clips[k].id != editor.selectedClipId) k,
            for (var k = 0; k < project.clips.length; k++)
              if (project.clips[k].id == editor.selectedClipId) k,
          ])
            Positioned(
              key: ValueKey('clip-${project.clips[i].id}'),
              left: _x(editor.clipStart(i)),
              top: videoTop,
              width: math.max(18, _x(project.clips[i].duration) - 2),
              height: _videoHeight,
              child: _ClipBlock(
                editor: editor,
                pps: pps,
                index: i,
                clip: project.clips[i],
                selected: editor.selectedClipId == project.clips[i].id,
              ),
            ),
          for (var i = 1; i < project.clips.length; i++)
            Positioned(
              left: _x(editor.clipStart(i)) - 13,
              top: videoTop + _videoHeight / 2 - 13,
              child: _TransitionMarker(
                transition: project.clips[i].transition,
                onTap: () {
                  editor.selectClip(project.clips[i].id);
                  onTransitionTap();
                },
              ),
            ),
          // Text + sticker tracks
          Positioned(
            left: 0,
            top: textTop,
            width: width,
            height: _overlayHeight,
            child: const _EmptyTrack(label: '', faint: true),
          ),
          Positioned(
            left: 0,
            top: stickerTop,
            width: width,
            height: _overlayHeight,
            child: const _EmptyTrack(label: '', faint: true),
          ),
          for (final item in project.overlays)
            Positioned(
              key: ValueKey('ov-${item.id}'),
              left: _x(item.start),
              top: item.type == EditorOverlayType.text ? textTop : stickerTop,
              width: math.max(28, _x(item.duration)),
              height: _overlayHeight,
              child: _OverlayBlock(
                editor: editor,
                pps: pps,
                item: item,
                selected: editor.selectedOverlayId == item.id,
              ),
            ),
          // Audio
          Positioned(
            left: 0,
            top: audioTop,
            width: width,
            height: _audioHeight,
            child: project.audioTracks.isEmpty
                ? const _EmptyTrack(label: 'Add music from the Media tab')
                : Container(
                    width: math.max(40, _x(total)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007BA7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomPaint(
                      painter: _WavePainter(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            project.audioTracks.first.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          // Playhead
          Positioned(
            left: _x(editor.position) - 1,
            top: 0,
            height: totalHeight,
            child: IgnorePointer(
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 8,
                    margin: const EdgeInsets.only(left: 0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(5)),
                    ),
                  ),
                  Expanded(child: Container(width: 2, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipBlock extends StatefulWidget {
  const _ClipBlock({
    required this.editor,
    required this.pps,
    required this.index,
    required this.clip,
    required this.selected,
  });

  final VideoEditorController editor;
  final double pps;
  final int index;
  final EditorClip clip;
  final bool selected;

  @override
  State<_ClipBlock> createState() => _ClipBlockState();
}

class _ClipBlockState extends State<_ClipBlock> {
  VideoEditorController get editor => widget.editor;
  double get pps => widget.pps;
  int get index => widget.index;
  EditorClip get clip => widget.clip;
  bool get selected => widget.selected;

  // Visual drag offset (px) and what reordering already shifted the block by.
  double _dx = 0;
  double _carry = 0;
  bool _lifted = false;

  @override
  Widget build(BuildContext context) {
    final isVideo =
        clip.type == EditorAssetType.video && clip.sourceDuration != null;
    // Snapshot taken when a trim drag starts (the block rebuilds mid-drag).
    (Duration, Duration, Duration) begin() {
      editor.selectClip(clip.id);
      return (clip.trimStart, clip.trimEnd, clip.duration);
    }

    Duration secs(double dx) =>
        Duration(microseconds: (dx / pps * 1e6).round());
    Duration scaled(double dx) =>
        Duration(microseconds: (dx / pps * 1e6 * clip.speed).round());

    final body = _HDrag(
        onStart: () {
          editor.selectClip(clip.id);
          _carry = 0;
          setState(() {
            _lifted = true;
            _dx = 0;
          });
        },
        onEnd: () => setState(() {
              _lifted = false;
              _dx = 0;
              _carry = 0;
            }),
        // The block follows the pointer; passing a neighbour's midpoint swaps
        // them and the offset is re-based so it keeps tracking the pointer.
        onUpdate: (total, delta, _) {
          var visual = total + _carry;
          final dir = visual > 0 ? 1 : -1;
          final list = editor.project.clips;
          final at = list.indexWhere((c) => c.id == clip.id);
          final n = at < 0 ? -1 : at + dir;
          if (n >= 0 && n < list.length) {
            final neighbour = list[n].duration.inMilliseconds / 1000 * pps;
            if (visual.abs() >= neighbour / 2) {
              editor.moveSelectedClip(dir);
              _carry -= dir * neighbour;
              visual = total + _carry;
            }
          }
          setState(() => _dx = visual);
          return false;
        },
        child: InkWell(
          onTap: () => editor.selectClip(clip.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF315B99),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.cyanAccent : Colors.white24,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (clip.type == EditorAssetType.image)
                  Opacity(opacity: .55, child: ClipVisual(clip: clip)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(clip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '${(clip.duration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                        style:
                            const TextStyle(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        body,
        if (selected && isVideo)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _EdgeHandle(
              onStart: begin,
              onUpdate: (total, snap) => editor.trimSelectedClip(
                  inPoint: (snap as (Duration, Duration, Duration)).$1 +
                      scaled(total)),
            ),
          ),
        if (selected)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _EdgeHandle(
              onStart: begin,
              onUpdate: (total, snap) {
                final st = snap as (Duration, Duration, Duration);
                if (isVideo) {
                  editor.trimSelectedClip(outPoint: st.$2 + scaled(total));
                } else {
                  editor.updateClipDuration(clip.id, st.$3 + secs(total),
                      undoable: true);
                }
              },
            ),
          ),
      ],
    );
    return Transform.translate(
      offset: Offset(_dx, 0),
      child: AnimatedScale(
        scale: _lifted ? 1.04 : 1,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _lifted
                ? const [BoxShadow(color: Colors.black87, blurRadius: 14)]
                : null,
          ),
          child: stack,
        ),
      ),
    );
  }
}

class _TransitionMarker extends StatelessWidget {
  const _TransitionMarker({required this.transition, required this.onTap});
  final EditorTransition transition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = transition != EditorTransition.none;
    return Tooltip(
      message: 'Transition: ${transition.label}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF6C5CE7) : const Color(0xFF2A3045),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
          ),
          child: Icon(transition.icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _OverlayBlock extends StatelessWidget {
  const _OverlayBlock({
    required this.editor,
    required this.pps,
    required this.item,
    required this.selected,
  });

  final VideoEditorController editor;
  final double pps;
  final EditorOverlay item;
  final bool selected;

  static const _minLen = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final isText = item.type == EditorOverlayType.text;
    final color = isText ? const Color(0xFF7C4DFF) : const Color(0xFFE0A800);
    Duration secs(double dx) =>
        Duration(microseconds: (dx / pps * 1e6).round());
    (Duration, Duration) begin() {
      editor.selectOverlay(item.id);
      return (item.start, item.duration);
    }

    final body = _HDrag(
      onStart: begin,
      onUpdate: (total, delta, snap) {
        var next = (snap as (Duration, Duration)).$1 + secs(total);
        if (next < Duration.zero) next = Duration.zero;
        editor.updateSelectedOverlay(start: next);
        return false;
      },
      child: InkWell(
        onTap: () {
          editor.selectOverlay(item.id);
          editor.seek(item.start);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        if (selected) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _EdgeHandle(
              onStart: begin,
              onUpdate: (total, snap) {
                // Move the start, keep the end fixed.
                final st = snap as (Duration, Duration);
                var s = st.$1 + secs(total);
                final end = st.$1 + st.$2;
                if (s < Duration.zero) s = Duration.zero;
                if (end - s < _minLen) s = end - _minLen;
                editor.updateSelectedOverlay(start: s, duration: end - s);
              },
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _EdgeHandle(
              onStart: begin,
              onUpdate: (total, snap) {
                var len = (snap as (Duration, Duration)).$2 + secs(total);
                if (len < _minLen) len = _minLen;
                editor.updateSelectedOverlay(duration: len);
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Horizontal drag that reports the accumulated distance. [onUpdate] may
/// return true to restart the accumulation (used for reordering).
class _HDrag extends StatefulWidget {
  const _HDrag({
    required this.child,
    required this.onUpdate,
    this.onStart,
    this.onEnd,
  });

  final Widget child;
  final dynamic Function()? onStart;
  final VoidCallback? onEnd;
  final bool Function(double total, double delta, dynamic snap) onUpdate;

  @override
  State<_HDrag> createState() => _HDragState();
}

class _HDragState extends State<_HDrag> {
  double _total = 0;
  dynamic _snap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) {
        _total = 0;
        _snap = widget.onStart?.call();
      },
      onHorizontalDragEnd: (_) => widget.onEnd?.call(),
      onHorizontalDragCancel: () => widget.onEnd?.call(),
      onHorizontalDragUpdate: (d) {
        _total += d.delta.dx;
        if (widget.onUpdate(_total, d.delta.dx, _snap)) _total = 0;
      },
      child: widget.child,
    );
  }
}

/// Grab handle on the left/right edge of a selected block.
class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle({required this.onStart, required this.onUpdate});
  final dynamic Function() onStart;
  final void Function(double total, dynamic snap) onUpdate;

  @override
  Widget build(BuildContext context) {
    return _HDrag(
      onStart: onStart,
      onUpdate: (total, _, snap) {
        onUpdate(total, snap);
        return false;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 12,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 3)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTrack extends StatelessWidget {
  const _EmptyTrack({required this.label, this.faint = false});
  final String label;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: faint ? .02 : .04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: mediaPanelBorder),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white30, fontSize: 10)),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.pps});
  final double pps;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    final step = pps >= 90 ? 1 : (pps >= 40 ? 2 : 5);
    for (var s = 0; s * pps <= size.width; s += step) {
      final x = s * pps;
      canvas.drawLine(Offset(x, size.height - 8), Offset(x, size.height), line);
      final minutes = s ~/ 60;
      final seconds = s % 60;
      final painter = TextPainter(
        text: TextSpan(
          text: '$minutes:${seconds.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x + 3, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.pps != pps;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: .5)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 4) {
      final wave = 4 + (math.sin(x * .17).abs() * (size.height * .5));
      canvas.drawLine(
        Offset(x, size.height / 2 - wave / 2),
        Offset(x, size.height / 2 + wave / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
