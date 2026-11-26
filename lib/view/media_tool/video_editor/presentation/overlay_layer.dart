import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/editor_catalog.dart';
import '../domain/video_editor_project.dart';
import 'editor_motion.dart';
import 'editor_visuals.dart';

/// One overlay drawn at [position] on the canvas, with enter / exit / loop
/// motion applied. Shared by the live preview and the export renderer so a
/// rendered frame always matches what the user sees.
class OverlayLayer extends StatelessWidget {
  const OverlayLayer({
    super.key,
    required this.overlay,
    required this.canvas,
    required this.unit,
    required this.position,
    required this.playing,
    this.selected = false,
    this.videoFrame,
    this.staticSticker = false,
    this.onTap,
    this.onDrag,
  });

  final EditorOverlay overlay;
  final Size canvas;

  /// Scale factor relating canvas size to the 360px design width.
  final double unit;
  final Duration position;
  final bool playing;
  final bool selected;

  /// Current frame of a video overlay.
  final ui.Image? videoFrame;

  /// Use the static Twemoji image (deterministic, for export).
  final bool staticSticker;
  final VoidCallback? onTap;
  final void Function(Offset delta)? onDrag;

  Widget _content(MotionFrame m, Duration local) {
    switch (overlay.type) {
      case EditorOverlayType.sticker:
        if (staticSticker) {
          final size = 76 * unit;
          return SizedBox(
            width: size,
            height: size,
            child: Image.network(
              EditorSticker(overlay.label, '').staticUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => FittedBox(
                child:
                    Text(overlay.label, style: const TextStyle(fontSize: 64)),
              ),
            ),
          );
        }
        return EditorStickerView(emoji: overlay.label, size: 76 * unit);
      case EditorOverlayType.sprite:
        return SpriteView(spec: overlay.sprite!, time: local, size: 96 * unit);
      case EditorOverlayType.particles:
        return ParticleView(kind: overlay.label, time: local, size: 160 * unit);
      case EditorOverlayType.video:
        final frame = videoFrame;
        return SizedBox(
          width: 140 * unit,
          height: 140 * unit,
          child: BlendBox(
            blendMode: BlendMode.screen,
            child: frame == null
                ? const SizedBox.shrink()
                : RawImage(
                    image: frame,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium),
          ),
        );
      case EditorOverlayType.text:
        return EditorTextView(
          text: overlay.label,
          style: overlay.style,
          scale: unit,
          maxWidth: canvas.width * .9,
          revealFraction: m.reveal,
          charMotion: m.charMotion,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = position - overlay.start;
    final m = computeMotion(overlay, position, playing, unit);

    Widget child = _content(m, local);

    if (m.glitch > 0 && overlay.type == EditorOverlayType.text) {
      Widget ghost(Color color, double dx) => Transform.translate(
            offset: Offset(dx * unit, 0),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
              child: Opacity(opacity: .75, child: _content(m, local)),
            ),
          );
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          ghost(const Color(0xFF00FFFF), -5),
          ghost(const Color(0xFFFF2D6F), 5),
          child,
        ],
      );
    }
    if (m.blur > .1) {
      child = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: m.blur, sigmaY: m.blur),
        child: child,
      );
    }

    return Positioned.fill(
      child: Align(
        alignment: Alignment(
          overlay.position.dx * 2 - 1,
          overlay.position.dy * 2 - 1,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onPanStart: onTap == null ? null : (_) => onTap!(),
          onPanUpdate: onDrag == null ? null : (d) => onDrag!(d.delta),
          child: Transform.translate(
            offset: Offset(m.dx, m.dy),
            child: Opacity(
              opacity: m.opacity,
              child: Transform.rotate(
                angle: overlay.rotation + m.rotation,
                child: Transform.scale(
                  scale: overlay.scale * m.scale,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            selected ? Colors.cyanAccent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
