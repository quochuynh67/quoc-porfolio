import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../domain/shader_catalog.dart';

final _programs = <String, Future<ui.FragmentProgram?>>{};

Future<ui.FragmentProgram?> _loadProgram(String asset) =>
    _programs.putIfAbsent(asset, () async {
      try {
        return await ui.FragmentProgram.fromAsset(asset);
      } catch (_) {
        return null;
      }
    });

/// Renders a gl-transitions style shader between [outgoing] and [incoming].
///
/// Both layers are captured to images (they are ordinary widgets, e.g. video
/// frames) and fed to the fragment shader. Until the shader and the captures
/// are ready, a plain cross-fade is shown. With [staticContent] the layers are
/// captured once (gallery thumbnails).
class GlTransitionView extends StatefulWidget {
  const GlTransitionView({
    super.key,
    required this.shaderId,
    required this.t,
    required this.outgoing,
    required this.incoming,
    this.staticContent = false,
  });

  final String shaderId;
  final double t;
  final Widget outgoing;
  final Widget incoming;
  final bool staticContent;

  @override
  State<GlTransitionView> createState() => _GlTransitionViewState();
}

class _GlTransitionViewState extends State<GlTransitionView> {
  final _outKey = GlobalKey();
  final _inKey = GlobalKey();
  ui.FragmentShader? _shader;
  ui.Image? _outImage;
  ui.Image? _inImage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  @override
  void didUpdateWidget(covariant GlTransitionView old) {
    super.didUpdateWidget(old);
    if (old.shaderId != widget.shaderId) {
      _shader?.dispose();
      _shader = null;
      _loadShader();
    }
  }

  Future<void> _loadShader() async {
    final info = shaderById(widget.shaderId);
    if (info == null) return;
    final id = widget.shaderId;
    final program = await _loadProgram(info.asset);
    if (mounted && id == widget.shaderId) {
      setState(() {
        _shader = program?.fragmentShader();
      });
    }
  }

  @override
  void dispose() {
    _outImage?.dispose();
    _inImage?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  void _scheduleCapture() {
    if (_busy) return;
    if (widget.staticContent && _outImage != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final a = _outKey.currentContext?.findRenderObject();
      final b = _inKey.currentContext?.findRenderObject();
      if (a is! RenderRepaintBoundary || b is! RenderRepaintBoundary) return;
      final size = a.size;
      if (size.isEmpty) return;
      final ratio = math.min(1.0, 540 / size.longestSide);
      final imgA = await a.toImage(pixelRatio: ratio);
      final imgB = await b.toImage(pixelRatio: ratio);
      if (!mounted) {
        imgA.dispose();
        imgB.dispose();
        return;
      }
      final oldA = _outImage, oldB = _inImage;
      setState(() {
        _outImage = imgA;
        _inImage = imgB;
      });
      oldA?.dispose();
      oldB?.dispose();
    } catch (_) {
      // Capture can fail while the layers are still laying out; retry on the
      // next frame.
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleCapture();
    final t = widget.t.clamp(0.0, 1.0);
    final ready = _shader != null && _outImage != null && _inImage != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _outKey, child: widget.outgoing),
        // Never fully transparent: a zero-opacity subtree is not painted, so
        // the capture of the incoming layer would come out blank.
        Opacity(
          opacity: math.max(t, 0.004),
          child: RepaintBoundary(key: _inKey, child: widget.incoming),
        ),
        if (ready)
          CustomPaint(
            painter: _ShaderPainter(_shader!, _outImage!, _inImage!, t),
          ),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader, this.from, this.to, this.progress);
  final ui.FragmentShader shader;
  final ui.Image from;
  final ui.Image to;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // A FragmentShader is a native GPU resource. It must stay alive until the
    // recorded canvas command has actually been rasterized. Disposing a newly
    // created shader here used to work by accident on some native backends,
    // but CanvasKit rasterizes later and produced blank/striped thumbnails.
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setImageSampler(0, from)
      ..setImageSampler(1, to);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}

Future<(ui.Image, ui.Image)>? _demoPhotos;

Future<ui.Image> _decodeAsset(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: 480);
  return (await codec.getNextFrame()).image;
}

/// Two real photos decoded once and shared by every gallery thumbnail.
Future<(ui.Image, ui.Image)> demoPhotos() => _demoPhotos ??= () async {
      final a = await _decodeAsset('assets/images/transitions/demo_a.jpg');
      final b = await _decodeAsset('assets/images/transitions/demo_b.jpg');
      return (a, b);
    }();

/// Cheap gallery thumbnail: paints the shader straight onto the shared demo
/// photos, with no widget capture per tile.
class ShaderPhotoThumb extends StatefulWidget {
  const ShaderPhotoThumb({super.key, required this.shaderId, required this.t});
  final String shaderId;
  final double t;

  @override
  State<ShaderPhotoThumb> createState() => _ShaderPhotoThumbState();
}

class _ShaderPhotoThumbState extends State<ShaderPhotoThumb> {
  ui.FragmentShader? _shader;
  (ui.Image, ui.Image)? _photos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ShaderPhotoThumb old) {
    super.didUpdateWidget(old);
    if (old.shaderId != widget.shaderId) {
      _shader?.dispose();
      _shader = null;
      _load();
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final info = shaderById(widget.shaderId);
    if (info == null) return;
    final id = widget.shaderId;
    final program = await _loadProgram(info.asset);
    final photos = await demoPhotos().catchError((_) {
      _demoPhotos = null;
      return Future<(ui.Image, ui.Image)>.error('photos');
    }).then<(ui.Image, ui.Image)?>((v) => v, onError: (_) => null);
    if (photos == null) return;
    if (mounted && id == widget.shaderId) {
      setState(() {
        _shader = program?.fragmentShader();
        _photos = photos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    if (photos == null) {
      return const Image(
        image: AssetImage('assets/images/transitions/demo_a.jpg'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    final shader = _shader;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: shader == null
            ? _FadePainter(photos.$1, photos.$2, widget.t)
            : _ShaderPainter(shader, photos.$1, photos.$2, widget.t),
      ),
    );
  }
}

class _FadePainter extends CustomPainter {
  _FadePainter(this.a, this.b, this.t);
  final ui.Image a;
  final ui.Image b;
  final double t;

  void _draw(Canvas c, Size size, ui.Image im, Paint p) => c.drawImageRect(
      im,
      Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
      Offset.zero & size,
      p);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, size, a, Paint());
    _draw(canvas, size, b, Paint()..color = Colors.white.withValues(alpha: t));
  }

  @override
  bool shouldRepaint(covariant _FadePainter old) => old.t != t;
}

/// Before/after style tile: the horizontal pointer position directly scrubs
/// the shader from the outgoing image on the left to the incoming image on the
/// right. Only the hovered tile runs its shader, so a big grid stays cheap.
/// [restProgress] pins a frame when not hovered (selected tile).
class ShaderScrubThumb extends StatefulWidget {
  const ShaderScrubThumb(
      {super.key, required this.shaderId, this.restProgress});
  final String shaderId;
  final double? restProgress;

  @override
  State<ShaderScrubThumb> createState() => _ShaderScrubThumbState();
}

class _ShaderScrubThumbState extends State<ShaderScrubThumb> {
  double? _t;

  void _set(Offset p, double width) {
    if (width <= 0) return;
    setState(() => _t = (p.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final progress = _t ?? widget.restProgress ?? 0.0;
    final interacting = _t != null;
    return LayoutBuilder(
      builder: (context, box) => MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        onEnter: (e) => _set(e.localPosition, box.maxWidth),
        onHover: (e) => _set(e.localPosition, box.maxWidth),
        onExit: (_) => setState(() => _t = null),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => _set(d.localPosition, box.maxWidth),
          onHorizontalDragStart: (d) => _set(d.localPosition, box.maxWidth),
          onHorizontalDragUpdate: (d) => _set(d.localPosition, box.maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Image(
                  image: AssetImage('assets/images/transitions/demo_a.jpg'),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                // Keep the renderer mounted so its shader program and both
                // textures are ready before the first pointer movement.
                ShaderPhotoThumb(
                  shaderId: widget.shaderId,
                  t: progress,
                ),
                if (interacting)
                  IgnorePointer(
                    child: CustomPaint(painter: _BeforeAfterPainter(progress)),
                  ),
                if (interacting) ...const [
                  Positioned(
                    left: 7,
                    top: 7,
                    child: _CompareLabel(text: 'A'),
                  ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: _CompareLabel(text: 'B'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareLabel extends StatelessWidget {
  const _CompareLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BeforeAfterPainter extends CustomPainter {
  _BeforeAfterPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * t;
    final center = Offset(x, size.height / 2);
    final shadow = Paint()
      ..color = Colors.black45
      ..strokeWidth = 4;
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), shadow);
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    canvas.drawCircle(center, 10, Paint()..color = Colors.black54);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.white.withValues(alpha: .95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final arrows = Path()
      ..moveTo(x - 2, center.dy - 4)
      ..lineTo(x - 6, center.dy)
      ..lineTo(x - 2, center.dy + 4)
      ..moveTo(x + 2, center.dy - 4)
      ..lineTo(x + 6, center.dy)
      ..lineTo(x + 2, center.dy + 4);
    canvas.drawPath(
      arrows,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BeforeAfterPainter old) => old.t != t;
}
