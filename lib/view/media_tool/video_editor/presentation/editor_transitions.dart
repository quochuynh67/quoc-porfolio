import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/editor_catalog.dart';
import '../domain/video_editor_project.dart';
import 'editor_visuals.dart';

/// Composes the [outgoing] and [incoming] layers for a transition at
/// progress [t] (0..1). Pure function so the preview and the gallery
/// thumbnails render identical frames. [fxOverlay] is drawn on top (effect
/// packs).
Widget buildTransitionFrame({
  required EditorTransition type,
  required double t,
  required Widget outgoing,
  required Widget incoming,
  Widget? fxOverlay,
}) {
  final p = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
  return LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      Widget frame;
      switch (type) {
        case EditorTransition.none:
          frame = incoming;
        case EditorTransition.fade:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            Opacity(opacity: p, child: incoming),
          ]);
        case EditorTransition.dipBlack:
          frame = Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Colors.black),
            if (p < .5)
              Opacity(opacity: 1 - p * 2, child: outgoing)
            else
              Opacity(opacity: (p - .5) * 2, child: incoming),
          ]);
        case EditorTransition.slideLeft:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            Transform.translate(
                offset: Offset((1 - p) * w, 0), child: incoming),
          ]);
        case EditorTransition.slideRight:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            Transform.translate(
                offset: Offset(-(1 - p) * w, 0), child: incoming),
          ]);
        case EditorTransition.slideUp:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            Transform.translate(
                offset: Offset(0, (1 - p) * h), child: incoming),
          ]);
        case EditorTransition.pushLeft:
          frame = Stack(fit: StackFit.expand, children: [
            Transform.translate(offset: Offset(-p * w, 0), child: outgoing),
            Transform.translate(
                offset: Offset((1 - p) * w, 0), child: incoming),
          ]);
        case EditorTransition.zoomIn:
          frame = Stack(fit: StackFit.expand, children: [
            incoming,
            Opacity(
              opacity: 1 - p,
              child: Transform.scale(scale: 1 + p * .9, child: outgoing),
            ),
          ]);
        case EditorTransition.zoomOut:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            Opacity(
              opacity: p,
              child: Transform.scale(scale: 1.8 - p * .8, child: incoming),
            ),
          ]);
        case EditorTransition.wipe:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            ClipRect(clipper: _WipeClipper(p), child: incoming),
          ]);
        case EditorTransition.spin:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            Opacity(
              opacity: p,
              child: Transform.rotate(
                angle: (1 - p) * math.pi * .6,
                child: Transform.scale(scale: .4 + p * .6, child: incoming),
              ),
            ),
          ]);
        case EditorTransition.blur:
          final sigma = math.sin(p * math.pi) * 14 + .001;
          frame = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
                sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
            child: Stack(fit: StackFit.expand, children: [
              outgoing,
              Opacity(opacity: p, child: incoming),
            ]),
          );
        case EditorTransition.flash:
          final peak = 1 - (2 * p - 1).abs();
          frame = Stack(fit: StackFit.expand, children: [
            p < .5 ? outgoing : incoming,
            Opacity(
              opacity: Curves.easeIn.transform(peak),
              child: const ColoredBox(color: Colors.white),
            ),
          ]);
        case EditorTransition.glitch:
          final base = p < .5 ? outgoing : incoming;
          final strength = math.sin(p * math.pi);
          const bands = 9;
          frame = Stack(fit: StackFit.expand, children: [
            base,
            for (var i = 0; i < bands; i++)
              Positioned.fill(
                child: ClipRect(
                  clipper: _BandClipper(i, bands),
                  child: Transform.translate(
                    offset: Offset(
                      math.sin(p * 40 + i * 12.9898) * w * .09 * strength,
                      0,
                    ),
                    child: p + i * .03 < .5 ? outgoing : incoming,
                  ),
                ),
              ),
            Opacity(
              opacity: .18 * strength,
              child: const ColoredBox(color: Color(0xFF00FFE1)),
            ),
          ]);
        case EditorTransition.circle:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            ClipPath(clipper: _CircleClipper(p), child: incoming),
          ]);
        case EditorTransition.blinds:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            ClipPath(clipper: _BlindsClipper(p, 8), child: incoming),
          ]);
        case EditorTransition.pixelate:
          frame = Stack(fit: StackFit.expand, children: [
            outgoing,
            ClipPath(clipper: _MosaicClipper(p), child: incoming),
          ]);
        case EditorTransition.fx:
          frame = p < .5 ? outgoing : incoming;
      }
      if (fxOverlay != null) {
        frame = Stack(fit: StackFit.expand, children: [frame, fxOverlay]);
      }
      return frame;
    },
  );
}

class _WipeClipper extends CustomClipper<Rect> {
  _WipeClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(covariant _WipeClipper old) => old.progress != progress;
}

class _BandClipper extends CustomClipper<Rect> {
  _BandClipper(this.index, this.count);
  final int index;
  final int count;

  @override
  Rect getClip(Size size) {
    // Alternate bands only so the image stays mostly intact.
    final bandH = size.height / count;
    return index.isEven
        ? Rect.fromLTWH(0, index * bandH, size.width, bandH)
        : Rect.zero;
  }

  @override
  bool shouldReclip(covariant _BandClipper old) => false;
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.progress);
  final double progress;

  @override
  Path getClip(Size size) {
    final radius = size.bottomRight(Offset.zero).distance / 2 * progress;
    return Path()
      ..addOval(
          Rect.fromCircle(center: size.center(Offset.zero), radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleClipper old) => old.progress != progress;
}

class _BlindsClipper extends CustomClipper<Path> {
  _BlindsClipper(this.progress, this.count);
  final double progress;
  final int count;

  @override
  Path getClip(Size size) {
    final path = Path();
    final stripe = size.width / count;
    for (var i = 0; i < count; i++) {
      path.addRect(
          Rect.fromLTWH(i * stripe, 0, stripe * progress, size.height));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _BlindsClipper old) => old.progress != progress;
}

class _MosaicClipper extends CustomClipper<Path> {
  _MosaicClipper(this.progress);
  final double progress;

  @override
  Path getClip(Size size) {
    const cols = 10;
    final cell = size.width / cols;
    final rows = (size.height / cell).ceil();
    final path = Path();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final h = math.sin((r * 12.9898 + c * 78.233)) * 43758.5453;
        final threshold = h - h.floorToDouble();
        if (threshold < progress) {
          path.addRect(Rect.fromLTWH(c * cell, r * cell, cell + .5, cell + .5));
        }
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _MosaicClipper old) => old.progress != progress;
}

/// Looping A→B preview of a transition used in the gallery.
class TransitionThumb extends StatefulWidget {
  const TransitionThumb({super.key, required this.type, this.fx});
  final EditorTransition type;
  final EditorFx? fx;

  @override
  State<TransitionThumb> createState() => _TransitionThumbState();
}

class _TransitionThumbState extends State<TransitionThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Widget _face(String letter, List<Color> colors) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(letter,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final a = _face('A', const [Color(0xFF2E5BFF), Color(0xFF1B2A6B)]);
    final b = _face('B', const [Color(0xFFFF7A59), Color(0xFFB0306A)]);
    final sprite = widget.fx?.sprite ??
        (widget.type == EditorTransition.fx ? builtinSprites.first : null);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final raw = ((_anim.value - .2) / .5).clamp(0.0, 1.0);
          Widget? overlay;
          if (widget.type == EditorTransition.fx) {
            overlay = sprite == null
                ? const Center(
                    child: Icon(Icons.movie_filter_rounded,
                        color: Colors.white70, size: 26))
                : Opacity(
                    opacity: math.sin(raw * math.pi),
                    child: SpriteView(
                      spec: sprite,
                      time: Duration(
                          milliseconds:
                              (raw * sprite.loopDuration.inMilliseconds)
                                  .round()),
                    ),
                  );
          }
          return buildTransitionFrame(
            type: widget.type,
            t: widget.type == EditorTransition.none ? 1 : raw,
            outgoing: a,
            incoming: b,
            fxOverlay: overlay,
          );
        },
      ),
    );
  }
}
