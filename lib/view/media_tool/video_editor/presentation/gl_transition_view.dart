import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/video_editor_project.dart';

/// Fragment-shader asset (ported from https://gl-transitions.com) per type.
String? glShaderAsset(EditorTransition t) => switch (t) {
      EditorTransition.glCrosswarp => 'shaders/transitions/crosswarp.frag',
      EditorTransition.glRipple => 'shaders/transitions/ripple.frag',
      EditorTransition.glSwirl => 'shaders/transitions/swirl.frag',
      EditorTransition.glWarp => 'shaders/transitions/warp.frag',
      EditorTransition.glDreamy => 'shaders/transitions/dreamy.frag',
      EditorTransition.glKaleido => 'shaders/transitions/kaleido.frag',
      EditorTransition.glPinwheel => 'shaders/transitions/pinwheel.frag',
      EditorTransition.glDots => 'shaders/transitions/dots.frag',
      _ => null,
    };

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
    required this.type,
    required this.t,
    required this.outgoing,
    required this.incoming,
    this.staticContent = false,
  });

  final EditorTransition type;
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
  ui.FragmentProgram? _program;
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
    if (old.type != widget.type) _loadShader();
  }

  Future<void> _loadShader() async {
    final asset = glShaderAsset(widget.type);
    if (asset == null) return;
    final program = await _loadProgram(asset);
    if (mounted) setState(() => _program = program);
  }

  @override
  void dispose() {
    _outImage?.dispose();
    _inImage?.dispose();
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
    final ready = _program != null && _outImage != null && _inImage != null;
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
            painter: _ShaderPainter(_program!, _outImage!, _inImage!, t),
          ),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.program, this.from, this.to, this.progress);
  final ui.FragmentProgram program;
  final ui.Image from;
  final ui.Image to;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setImageSampler(0, from)
      ..setImageSampler(1, to);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    shader.dispose();
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}
