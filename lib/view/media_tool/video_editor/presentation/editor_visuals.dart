import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/editor_catalog.dart';
import '../domain/video_editor_project.dart';

// ------------------------------------------------------------------- text

TextStyle editorFont(EditorTextStyle s, {Color? color, double scale = 1}) {
  final base = TextStyle(
    fontSize: s.fontSize * scale,
    fontWeight: FontWeight.values[((s.weight / 100).round() - 1).clamp(0, 8)],
    fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: s.letterSpacing * scale,
    color: color ?? s.color,
    height: 1.15,
  );
  try {
    return GoogleFonts.getFont(s.fontFamily, textStyle: base);
  } catch (_) {
    return base;
  }
}

/// Per-letter transform used by wave / letter-rise animations.
typedef CharMotion = ({double dy, double opacity, double scale}) Function(
    int index, int count);

/// Renders a text overlay in the given [style]. Used in the preview, the
/// template gallery and the inspector so they always match.
class EditorTextView extends StatelessWidget {
  const EditorTextView({
    super.key,
    required this.text,
    required this.style,
    this.scale = 1,
    this.maxWidth,
    this.revealFraction = 1,
    this.charMotion,
  });

  final String text;
  final EditorTextStyle style;
  final double scale;
  final double? maxWidth;

  /// 0..1 left-to-right reveal (typewriter).
  final double revealFraction;
  final CharMotion? charMotion;

  Widget _run(String display, TextStyle ts) {
    final motion = charMotion;
    if (motion == null) {
      return Text(display, textAlign: TextAlign.center, style: ts);
    }
    final lines = display.split('\n');
    final total = display.replaceAll('\n', '').length;
    var index = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final ch in line.characters)
                Builder(builder: (context) {
                  final m = motion(index++, total);
                  return Opacity(
                    opacity: m.opacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, m.dy),
                      child: Transform.scale(
                        scale: m.scale,
                        child: Text(ch, style: ts),
                      ),
                    ),
                  );
                }),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = style.uppercase ? text.toUpperCase() : text;
    final shadows = <Shadow>[
      if (style.glow != null) ...[
        Shadow(color: style.glow!, blurRadius: 6 * scale),
        Shadow(color: style.glow!, blurRadius: 16 * scale),
        Shadow(
            color: style.glow!.withValues(alpha: .7), blurRadius: 30 * scale),
      ] else if (style.shadow)
        Shadow(
            color: Colors.black.withValues(alpha: .7),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale)),
    ];

    Widget content;
    if (style.gradient != null) {
      content = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          colors: style.gradient!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
        child:
            _run(display, editorFont(style, color: Colors.white, scale: scale)),
      );
    } else if (style.stroke != null && style.strokeWidth > 0) {
      final fill = editorFont(style, scale: scale);
      content = Stack(
        children: [
          _run(
            display,
            fill.copyWith(
              color: null,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeWidth = style.strokeWidth * scale
                ..color = style.stroke!,
            ),
          ),
          _run(display, fill),
        ],
      );
    } else {
      content = _run(
          display, editorFont(style, scale: scale).copyWith(shadows: shadows));
    }

    if (revealFraction < 1) {
      content = ClipRect(
        clipper: _RevealClipper(revealFraction),
        child: content,
      );
    }

    final hasBox = style.background != null;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(style.radius * scale),
        ),
        child: Padding(
          padding: hasBox
              ? EdgeInsets.symmetric(
                  horizontal: 12 * scale, vertical: 6 * scale)
              : EdgeInsets.zero,
          child: content,
        ),
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.fraction);
  final double fraction;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction.clamp(0.0, 1.0), size.height);
  @override
  bool shouldReclip(covariant _RevealClipper old) => old.fraction != fraction;
}

// ---------------------------------------------------------------- sticker

/// Animated Noto emoji from the Google CDN, falling back to a static Twemoji
/// PNG and finally to the plain emoji glyph when offline.
class EditorStickerView extends StatelessWidget {
  const EditorStickerView({super.key, required this.emoji, this.size = 64});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sticker = EditorSticker(emoji, '');
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        sticker.animatedUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => Image.network(
          sticker.staticUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => FittedBox(
            child: Text(emoji, style: const TextStyle(fontSize: 64)),
          ),
        ),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Center(
                child: Opacity(
                  opacity: .35,
                  child: FittedBox(
                    child: Text(emoji, style: const TextStyle(fontSize: 64)),
                  ),
                ),
              ),
      ),
    );
  }
}

// ----------------------------------------------------------------- sprite

class SpriteImageCache {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(SpriteSpec spec) {
    return _cache.putIfAbsent(spec.cacheKey, () async {
      try {
        if (spec.bytes != null) {
          return await decodeImageFromList(spec.bytes!);
        }
        final completer = Completer<ui.Image?>();
        final stream =
            NetworkImage(spec.url!).resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, _) {
            if (!completer.isCompleted) completer.complete(info.image);
            stream.removeListener(listener);
          },
          onError: (error, stack) {
            if (!completer.isCompleted) completer.complete(null);
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        return await completer.future;
      } catch (_) {
        return null;
      }
    });
  }
}

/// Plays a sprite sheet. With [time] the frame follows an external clock
/// (editor playhead); without it a private ticker loops the animation.
class SpriteView extends StatefulWidget {
  const SpriteView({super.key, required this.spec, this.time, this.size});
  final SpriteSpec spec;
  final Duration? time;
  final double? size;

  @override
  State<SpriteView> createState() => _SpriteViewState();
}

class _SpriteViewState extends State<SpriteView>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  late final Ticker _ticker;
  Duration _own = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _own = elapsed));
    if (widget.time == null) _ticker.start();
    _load();
  }

  @override
  void didUpdateWidget(covariant SpriteView old) {
    super.didUpdateWidget(old);
    if (old.spec.cacheKey != widget.spec.cacheKey) {
      _image = null;
      _load();
    }
  }

  Future<void> _load() async {
    final image = await SpriteImageCache.load(widget.spec);
    if (mounted) setState(() => _image = image);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.time ?? _own;
    final spec = widget.spec;
    final frame =
        (t.inMicroseconds / 1e6 * spec.fps).floor().abs() % spec.frames;
    final painter = _SpritePainter(_image, spec, frame);
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter, size: Size.infinite),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.image, this.spec, this.frame);
  final ui.Image? image;
  final SpriteSpec spec;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) {
      final p = Paint()..color = Colors.white12;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
          p);
      return;
    }
    final fw = img.width / spec.cols;
    final fh = img.height / spec.rows;
    final col = frame % spec.cols;
    final row = frame ~/ spec.cols;
    final src = Rect.fromLTWH(col * fw, row * fh, fw, fh);
    final scale = math.min(size.width / fw, size.height / fh);
    final dst = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: fw * scale,
      height: fh * scale,
    );
    canvas.drawImageRect(
        img, src, dst, Paint()..filterQuality = FilterQuality.low);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.image != image || old.frame != frame || old.spec != spec;
}

// --------------------------------------------------------------- particles

/// Procedural particle stickers (deterministic for a given [seconds]).
class ParticleView extends StatefulWidget {
  const ParticleView({super.key, required this.kind, this.time, this.size});
  final String kind;
  final Duration? time;
  final double? size;

  @override
  State<ParticleView> createState() => _ParticleViewState();
}

class _ParticleViewState extends State<ParticleView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _own = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => setState(() => _own = e));
    if (widget.time == null) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = (widget.time ?? _own).inMicroseconds / 1e6;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ParticlePainter(widget.kind, t),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.kind, this.t);
  final String kind;
  final double t;

  static const _palette = [
    Color(0xFFFF4D8D),
    Color(0xFFFFD23F),
    Color(0xFF3DDC97),
    Color(0xFF4DA3FF),
    Color(0xFFB66DFF),
    Color(0xFFFF8A3D),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case 'confetti':
        _confetti(canvas, size);
      case 'hearts':
        _hearts(canvas, size);
      case 'sparkles':
        _sparkles(canvas, size);
      case 'snow':
        _snow(canvas, size);
      case 'fireworks':
        _fireworks(canvas, size);
    }
  }

  void _confetti(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final x = rnd.nextDouble();
      final speed = .25 + rnd.nextDouble() * .35;
      final phase = rnd.nextDouble();
      final y = ((t * speed + phase) % 1.0) * 1.2 - .1;
      final sway = math.sin(t * 3 + i) * .02;
      final spin = t * (2 + rnd.nextDouble() * 4) + i;
      paint.color = _palette[i % _palette.length];
      canvas.save();
      canvas.translate((x + sway) * size.width, y * size.height);
      canvas.rotate(spin);
      canvas.scale(1, math.cos(spin * 1.3).abs() * .8 + .2);
      canvas.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), paint);
      canvas.restore();
    }
  }

  Path _heart(double s) {
    final p = Path()
      ..moveTo(0, s * .35)
      ..cubicTo(-s * .9, -s * .2, -s * .45, -s * .9, 0, -s * .4)
      ..cubicTo(s * .45, -s * .9, s * .9, -s * .2, 0, s * .35);
    return p;
  }

  void _hearts(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 16; i++) {
      final x = .1 + rnd.nextDouble() * .8;
      final speed = .18 + rnd.nextDouble() * .22;
      final phase = rnd.nextDouble();
      final progress = (t * speed + phase) % 1.0;
      final y = 1.1 - progress * 1.3;
      final sway = math.sin(t * 2 + i * 1.7) * .04;
      final s = 8 + rnd.nextDouble() * 14;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate((x + sway) * size.width, y * size.height);
      canvas.drawPath(
        _heart(s),
        Paint()
          ..color = Color.lerp(const Color(0xFFFF4D8D), const Color(0xFFFF9AB5),
                  rnd.nextDouble())!
              .withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  Path _star(double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final rad = i.isEven ? r : r * .22;
      final pt = Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _sparkles(Canvas canvas, Size size) {
    final rnd = math.Random(3);
    for (var i = 0; i < 22; i++) {
      final x = rnd.nextDouble();
      final y = rnd.nextDouble();
      final period = .8 + rnd.nextDouble() * 1.4;
      final phase = rnd.nextDouble() * period;
      final k = ((t + phase) % period) / period;
      final twinkle = math.sin(k * math.pi);
      final r = (4 + rnd.nextDouble() * 10) * twinkle;
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(k * math.pi / 2);
      canvas.drawPath(
        _star(r),
        Paint()
          ..color = Colors.white.withValues(alpha: .4 + .6 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
      canvas.restore();
    }
  }

  void _snow(Canvas canvas, Size size) {
    final rnd = math.Random(5);
    final paint = Paint()..color = Colors.white.withValues(alpha: .85);
    for (var i = 0; i < 60; i++) {
      final x = rnd.nextDouble();
      final speed = .08 + rnd.nextDouble() * .16;
      final phase = rnd.nextDouble();
      final y = ((t * speed + phase) % 1.0) * 1.1 - .05;
      final sway = math.sin(t * 1.4 + i) * .02;
      canvas.drawCircle(Offset((x + sway) * size.width, y * size.height),
          1.5 + rnd.nextDouble() * 3, paint);
    }
  }

  void _fireworks(Canvas canvas, Size size) {
    const bursts = 3;
    for (var b = 0; b < bursts; b++) {
      final rnd = math.Random(b * 13 + 2);
      final period = 1.8;
      final local = ((t + b * .6) % period) / period; // 0..1
      final cx = (.25 + rnd.nextDouble() * .5) * size.width;
      final cy = (.2 + rnd.nextDouble() * .35) * size.height;
      final color = _palette[(b + (t / period).floor()) % _palette.length];
      for (var i = 0; i < 28; i++) {
        final angle = i / 28 * math.pi * 2;
        final speed = (.5 + rnd.nextDouble() * .5) * size.shortestSide * .38;
        final d = speed * Curves.easeOut.transform(local);
        final gravity = local * local * size.shortestSide * .12;
        final pos = Offset(
            cx + math.cos(angle) * d, cy + math.sin(angle) * d + gravity);
        canvas.drawCircle(
          pos,
          2.4 * (1 - local) + .4,
          Paint()..color = color.withValues(alpha: (1 - local).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.t != t || old.kind != kind;
}

// ------------------------------------------------------------------ filter

List<double> _mul(List<double> a, List<double> b) {
  // 4x5 affine colour matrices: result = a ∘ b (apply b first, then a).
  final out = List<double>.filled(20, 0);
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 5; c++) {
      var v = 0.0;
      for (var k = 0; k < 4; k++) {
        v += a[r * 5 + k] * b[k * 5 + c];
      }
      if (c == 4) v += a[r * 5 + 4];
      out[r * 5 + c] = v;
    }
  }
  return out;
}

/// Preset colour matrix blended towards identity by [EditorFilter.intensity].
List<double> presetMatrix(EditorFilter f) {
  final preset = filterPresetById(f.preset);
  final k = f.intensity.clamp(0.0, 1.0);
  final base = preset.matrix;
  if (k >= 1) return List<double>.from(base);
  return [
    for (var i = 0; i < 20; i++)
      identityMatrix[i] + (base[i] - identityMatrix[i]) * k,
  ];
}

/// Brightness / contrast / saturation only (no preset).
List<double> adjustMatrix(EditorFilter f) =>
    _adjust(f, List<double>.from(identityMatrix));

List<double> filterMatrix(EditorFilter f) => _adjust(f, presetMatrix(f));

List<double> _adjust(EditorFilter f, List<double> start) {
  var m = start;
  if (f.saturation != 0) {
    final s = 1 + f.saturation;
    const lr = .2126, lg = .7152, lb = .0722;
    m = _mul([
      lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0,
      lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0,
      0, 0, 0, 1, 0,
    ], m);
  }
  if (f.contrast != 0) {
    final c = 1 + f.contrast;
    final o = 128 * (1 - c);
    m = _mul([
      c, 0, 0, 0, o, //
      0, c, 0, 0, o,
      0, 0, c, 0, o,
      0, 0, 0, 1, 0,
    ], m);
  }
  if (f.brightness != 0) {
    final o = 255 * f.brightness * .5;
    m = _mul([
      1, 0, 0, 0, o, //
      0, 1, 0, 0, o,
      0, 0, 1, 0, o,
      0, 0, 0, 1, 0,
    ], m);
  }
  return m;
}

/// Applies a clip's colour grading to [child].
class FilteredClip extends StatelessWidget {
  const FilteredClip({super.key, required this.filter, required this.child});
  final EditorFilter filter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (filter.isIdentity) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(filterMatrix(filter)),
      child: child,
    );
  }
}

// ------------------------------------------------------------------- clip

class ClipVisual extends StatelessWidget {
  const ClipVisual({super.key, required this.clip, this.fit = BoxFit.cover});
  final EditorClip clip;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (clip.type == EditorAssetType.image) {
      return FilteredClip(
        filter: clip.filter,
        child: Image.memory(
          clip.bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: Colors.black26,
            child: Center(
              child:
                  Icon(Icons.broken_image_outlined, color: Colors.orangeAccent),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF203A63), Color(0xFF121827), Color(0xFF42245C)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded,
            color: Colors.white70, size: 34),
      ),
    );
  }
}

/// Composites its child with [blendMode] against whatever is behind it
/// (used for black-background effect videos: screen blend).
class BlendBox extends SingleChildRenderObjectWidget {
  const BlendBox({super.key, required this.blendMode, super.child});
  final BlendMode blendMode;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBlendBox(blendMode);

  @override
  void updateRenderObject(BuildContext context, _RenderBlendBox render) {
    render.blendMode = blendMode;
  }
}

class _RenderBlendBox extends RenderProxyBox {
  _RenderBlendBox(this._blendMode);
  BlendMode _blendMode;
  set blendMode(BlendMode v) {
    if (v == _blendMode) return;
    _blendMode = v;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.saveLayer(
      offset & size,
      Paint()..blendMode = _blendMode,
    );
    super.paint(context, offset);
    context.canvas.restore();
  }
}
