import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/video_editor_project.dart';
import 'editor_visuals.dart';

class MotionFrame {
  const MotionFrame({
    this.opacity = 1,
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotation = 0,
    this.blur = 0,
    this.reveal = 1,
    this.charMotion,
    this.glitch = 0,
  });

  final double opacity;
  final double dx;
  final double dy;
  final double scale;
  final double rotation;
  final double blur;
  final double reveal;
  final CharMotion? charMotion;

  /// 0..1 glitch intensity (ghost copies + jitter).
  final double glitch;
}

Duration enterDuration(EditorOverlay o) {
  final cap = Duration(milliseconds: o.duration.inMilliseconds ~/ 2);
  final chars = o.label.length;
  final base = switch (o.enter) {
    OverlayEnter.typewriter =>
      Duration(milliseconds: (chars * 70).clamp(600, 2600)),
    OverlayEnter.letterRise =>
      Duration(milliseconds: (500 + chars * 50).clamp(600, 2200)),
    OverlayEnter.bounce => const Duration(milliseconds: 800),
    _ => const Duration(milliseconds: 500),
  };
  return base < cap ? base : cap;
}

const exitDuration = Duration(milliseconds: 350);

double _clamp01(double v) => v.clamp(0.0, 1.0);

/// Computes the animated state of [o] at [position].
///
/// Enter / exit only run while [playing]: a paused playhead always shows the
/// settled item (so adding or selecting something never makes it vanish).
/// [unit] scales pixel offsets with the canvas size.
MotionFrame computeMotion(
  EditorOverlay o,
  Duration position,
  bool playing,
  double unit,
) {
  final local = position - o.start;
  final remaining = o.end - position;
  final t = local.inMicroseconds / 1e6;

  var opacity = 1.0, dx = 0.0, dy = 0.0, scale = 1.0, rot = 0.0, blur = 0.0;
  var reveal = 1.0;
  CharMotion? charMotion;
  var glitch = 0.0;

  if (playing && o.enter != OverlayEnter.none) {
    final d = enterDuration(o);
    if (local < d) {
      final p = _clamp01(local.inMicroseconds / d.inMicroseconds);
      switch (o.enter) {
        case OverlayEnter.none:
          break;
        case OverlayEnter.fade:
          opacity = Curves.easeOut.transform(p);
        case OverlayEnter.slideUp:
          final e = Curves.easeOutCubic.transform(p);
          dy = (1 - e) * 70 * unit;
          opacity = e;
        case OverlayEnter.slideDown:
          final e = Curves.easeOutCubic.transform(p);
          dy = -(1 - e) * 70 * unit;
          opacity = e;
        case OverlayEnter.slideLeft:
          final e = Curves.easeOutCubic.transform(p);
          dx = (1 - e) * 110 * unit;
          opacity = e;
        case OverlayEnter.slideRight:
          final e = Curves.easeOutCubic.transform(p);
          dx = -(1 - e) * 110 * unit;
          opacity = e;
        case OverlayEnter.pop:
          scale = Curves.easeOutBack.transform(p);
          opacity = _clamp01(p * 4);
        case OverlayEnter.zoom:
          final e = Curves.easeOutCubic.transform(p);
          scale = 2.4 - 1.4 * e;
          opacity = e;
        case OverlayEnter.spin:
          final e = Curves.easeOutCubic.transform(p);
          rot = (1 - e) * -math.pi * 2;
          scale = e;
          opacity = e;
        case OverlayEnter.bounce:
          final e = Curves.bounceOut.transform(p);
          dy = -(1 - e) * 220 * unit;
          opacity = _clamp01(p * 5);
        case OverlayEnter.blur:
          final e = Curves.easeOut.transform(p);
          blur = (1 - e) * 14 * unit;
          opacity = e;
        case OverlayEnter.typewriter:
          reveal = p;
        case OverlayEnter.letterRise:
          charMotion = (i, n) {
            final cp = _clamp01((local.inMilliseconds - i * 50) / 420.0);
            final e = Curves.easeOutBack.transform(cp);
            return (dy: (1 - e) * 26 * unit, opacity: cp, scale: .6 + .4 * e);
          };
      }
    }
  }

  if (playing && o.exit != OverlayExit.none && remaining < exitDuration) {
    final q =
        _clamp01(1 - remaining.inMicroseconds / exitDuration.inMicroseconds);
    final e = Curves.easeIn.transform(q);
    switch (o.exit) {
      case OverlayExit.none:
        break;
      case OverlayExit.fade:
        opacity *= 1 - e;
      case OverlayExit.slideDown:
        dy += e * 70 * unit;
        opacity *= 1 - e;
      case OverlayExit.slideUp:
        dy -= e * 70 * unit;
        opacity *= 1 - e;
      case OverlayExit.zoom:
        scale *= 1 + e * .9;
        opacity *= 1 - e;
      case OverlayExit.pop:
        scale *= 1 - e;
        opacity *= 1 - e;
    }
  }

  switch (o.loop) {
    case OverlayLoop.none:
      break;
    case OverlayLoop.pulse:
      scale *= 1 + .07 * math.sin(t * 2 * math.pi * 1.6);
    case OverlayLoop.float:
      dy += math.sin(t * 2 * math.pi * .7) * 9 * unit;
    case OverlayLoop.shake:
      dx += math.sin(t * 48) * 3.5 * unit;
      dy += math.cos(t * 41) * 2 * unit;
    case OverlayLoop.swing:
      rot += math.sin(t * 3.2) * .09;
    case OverlayLoop.wave:
      final prior = charMotion;
      charMotion = (i, n) {
        final base = prior?.call(i, n) ?? (dy: 0.0, opacity: 1.0, scale: 1.0);
        return (
          dy: base.dy + math.sin(t * 5 - i * .6) * 8 * unit,
          opacity: base.opacity,
          scale: base.scale,
        );
      };
    case OverlayLoop.glitch:
      final slot = (t * 10).floor();
      final burst = (slot * 7919) % 5 == 0;
      if (burst) {
        glitch = 1;
        dx += ((slot * 31) % 7 - 3) * 2.2 * unit;
      }
    case OverlayLoop.blink:
      opacity *= math.sin(t * 9) > -.2 ? 1 : .3;
    case OverlayLoop.spin:
      rot += t * 2.2;
  }

  return MotionFrame(
    opacity: _clamp01(opacity),
    dx: dx,
    dy: dy,
    scale: scale,
    rotation: rot,
    blur: blur,
    reveal: reveal,
    charMotion: charMotion,
    glitch: glitch,
  );
}
