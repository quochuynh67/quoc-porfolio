import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../application/export_plan.dart';
import '../domain/editor_catalog.dart';
import '../domain/video_editor_project.dart';
import 'editor_visuals.dart';

/// Re-encodes any decodable image as PNG (FFmpeg-friendly).
Future<Uint8List> imageToPng(Uint8List bytes) async {
  final image = await decodeImageFromList(bytes);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

bool isExportableOverlay(EditorOverlay o) =>
    o.type == EditorOverlayType.text || o.type == EditorOverlayType.sticker;

/// Renders every text / emoji overlay to a transparent, full-canvas PNG at the
/// export resolution, using the same widgets as the live preview.
Future<Map<String, Uint8List>> renderOverlayPngs(
  BuildContext context,
  VideoEditorProject project,
  int shortSide,
) async {
  final (outW, outH) = exportSize(project.aspectRatio, shortSide);
  const pixelRatio = 2.0;
  final logical = Size(outW / pixelRatio, outH / pixelRatio);
  final unit = (logical.width / 360).clamp(.5, 2.5).toDouble();
  final overlay = Overlay.of(context, rootOverlay: true);
  final result = <String, Uint8List>{};

  for (final o in project.overlays.where(isExportableOverlay)) {
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -logical.width * 2 - 40,
        top: 0,
        width: logical.width,
        height: logical.height,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: key,
            child: _ExportOverlay(overlay: o, canvas: logical, unit: unit),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      if (o.type == EditorOverlayType.sticker) {
        final url = EditorSticker(o.label, '').staticUrl;
        if (context.mounted) {
          await precacheImage(NetworkImage(url), context).catchError((_) {});
        }
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data != null) result[o.id] = data.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
  return result;
}

class _ExportOverlay extends StatelessWidget {
  const _ExportOverlay({
    required this.overlay,
    required this.canvas,
    required this.unit,
  });
  final EditorOverlay overlay;
  final Size canvas;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (overlay.type == EditorOverlayType.sticker) {
      final size = 76 * unit;
      content = SizedBox(
        width: size,
        height: size,
        child: Image.network(
          EditorSticker(overlay.label, '').staticUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => FittedBox(
            child: Text(overlay.label, style: const TextStyle(fontSize: 64)),
          ),
        ),
      );
    } else {
      content = EditorTextView(
        text: overlay.label,
        style: overlay.style,
        scale: unit,
        maxWidth: canvas.width * .9,
      );
    }
    return SizedBox(
      width: canvas.width,
      height: canvas.height,
      child: Align(
        alignment: Alignment(
          overlay.position.dx * 2 - 1,
          overlay.position.dy * 2 - 1,
        ),
        child: Transform.rotate(
          angle: overlay.rotation,
          child: Transform.scale(
            scale: overlay.scale,
            child: Padding(padding: const EdgeInsets.all(4), child: content),
          ),
        ),
      ),
    );
  }
}
