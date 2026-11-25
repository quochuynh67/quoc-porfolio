import 'dart:math' as math;

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
                    return SingleChildScrollView(
                        child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TrackLabels(),
                        SizedBox(
                          width: available,
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
          for (var i = 0; i < project.clips.length; i++)
            Positioned(
              left: _x(editor.clipStart(i)),
              top: videoTop,
              width: math.max(18, _x(project.clips[i].duration) - 2),
              height: _videoHeight,
              child: _ClipBlock(
                editor: editor,
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
              left: _x(item.start),
              top: item.type == EditorOverlayType.text ? textTop : stickerTop,
              width: math.max(28, _x(item.duration)),
              height: _overlayHeight,
              child: _OverlayBlock(
                editor: editor,
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

class _ClipBlock extends StatelessWidget {
  const _ClipBlock({
    required this.editor,
    required this.clip,
    required this.selected,
  });

  final VideoEditorController editor;
  final EditorClip clip;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                    style: const TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
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
    required this.item,
    required this.selected,
  });

  final VideoEditorController editor;
  final EditorOverlay item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isText = item.type == EditorOverlayType.text;
    final color = isText ? const Color(0xFF7C4DFF) : const Color(0xFFE0A800);
    return InkWell(
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
