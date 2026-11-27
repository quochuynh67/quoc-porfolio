import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/video_editor_project.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/export_dialog.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/export_prep.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL1WQAAAABJRU5ErkJggg==',
);

VideoEditorProject _project() => VideoEditorProject(
      clips: [
        EditorClip(
          id: 'a',
          name: 'A.png',
          type: EditorAssetType.image,
          bytes: _png,
        ),
        EditorClip(
          id: 'b',
          name: 'B.png',
          type: EditorAssetType.image,
          bytes: _png,
          transition: EditorTransition.shader,
          shaderId: 'diamondwipe',
        ),
      ],
      overlays: const [
        EditorOverlay(
          id: 'title',
          type: EditorOverlayType.text,
          label: 'Hello',
          start: Duration.zero,
          duration: Duration(seconds: 2),
        ),
        EditorOverlay(
          id: 'sticker',
          type: EditorOverlayType.sticker,
          label: '✨',
          start: Duration.zero,
          duration: Duration(seconds: 2),
        ),
      ],
    );

void main() {
  testWidgets('export media frame is valid below a repaint boundary',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 240,
        height: 240,
        child: RepaintBoundary(
          child: exportMediaFrame(null, fit: BoxFit.cover),
        ),
      ),
    ));

    expect(find.byType(Positioned), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Future<void> openDialog(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ExportDialog(project: _project()),
            ),
            child: const Text('Export'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Export'));
    await tester.pump();
  }

  testWidgets('export review explains included transitions and overlays',
      (tester) async {
    await openDialog(tester, const Size(1100, 850));

    expect(find.text('Export video'), findsOneWidget);
    expect(find.text('Included in this export'), findsOneWidget);
    expect(find.text('Transitions 1'), findsOneWidget);
    expect(find.text('Text 1'), findsOneWidget);
    expect(find.text('Stickers 1'), findsOneWidget);
    expect(find.text('Start export'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export dialog stays responsive on mobile', (tester) async {
    await openDialog(tester, const Size(390, 780));

    expect(find.text('Export video'), findsOneWidget);
    expect(find.text('720p · HD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
