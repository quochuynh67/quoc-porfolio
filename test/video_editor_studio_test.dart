import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/application/video_editor_controller.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/application/template_store.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/editor_catalog.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/editor_template.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/editor_motion.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/video_editor_project.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/video_editor_studio_screen.dart';

// 1x1 transparent PNG.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

VideoEditorController _seeded() {
  final c = VideoEditorController();
  c.addClip(name: 'a.png', type: EditorAssetType.image, bytes: _png);
  c.addClip(name: 'b.png', type: EditorAssetType.image, bytes: _png);
  c.addText(textTemplates.firstWhere((t) => t.id == 'bold-title'));
  c.addSticker(stickerCategories.values.first.first);
  return c;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('transition becomes active at the start of the 2nd clip', () {
    final c = _seeded();
    c.seek(const Duration(seconds: 5, milliseconds: 200));
    final t = c.activeTransition;
    expect(t, isNotNull);
    expect(t!.type, EditorTransition.fade);
    expect(t.progress, closeTo(.25, .01));
    c.seek(const Duration(seconds: 7));
    expect(c.activeTransition, isNull);
    c.seek(const Duration(seconds: 2));
    expect(c.activeTransition, isNull);
  });

  test('overlays are active at the playhead after being added', () {
    final c = _seeded();
    expect(c.activeOverlays, isNotEmpty);
  });

  logicTests();
  visibilityTests();

  for (final size in const [
    Size(390, 780),
    Size(700, 900),
    Size(820, 1100),
    Size(1024, 700),
    Size(1440, 900),
    Size(1440, 560),
  ]) {
    testWidgets('renders without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = _seeded();
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: VideoEditorStudioScreen(controller: controller, store: TemplateStore(persist: false))),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      // Walk through every tool tab.
      for (final label in ['Text', 'Stickers', 'Transitions', 'Filters', 'Templates', 'Analyze', 'Edit']) {
        final tab = find.text(label).first;
        await tester.ensureVisible(tab);
        await tester.tap(tab, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      controller.seek(const Duration(seconds: 5, milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }
}

void logicTests() {
  test('enter animations only run while playing (paused = settled)', () {
    final o = EditorOverlay(
      id: 'o',
      type: EditorOverlayType.text,
      label: 'Hi',
      start: Duration.zero,
      duration: const Duration(seconds: 4),
      enter: OverlayEnter.pop,
    );
    final paused = computeMotion(o, Duration.zero, false, 1);
    expect(paused.opacity, 1);
    expect(paused.scale, 1);
    final playing = computeMotion(o, const Duration(milliseconds: 50), true, 1);
    expect(playing.scale, lessThan(1));
    final settled = computeMotion(o, const Duration(seconds: 2), true, 1);
    expect(settled.scale, 1);
  });

  test('trim and speed update the timeline length', () {
    final c = VideoEditorController();
    c.addClip(name: 'v.mp4', type: EditorAssetType.video, bytes: _png);
    final id = c.selectedClipId!;
    c.setSourceDuration(id, const Duration(seconds: 10));
    expect(c.project.duration, const Duration(seconds: 10));
    c.trimSelectedClip(
        inPoint: const Duration(seconds: 2), outPoint: const Duration(seconds: 8));
    expect(c.project.duration, const Duration(seconds: 6));
    c.setSelectedClipSpeed(2);
    expect(c.project.duration, const Duration(seconds: 3));
    expect(c.selectedClip!.trimStart, const Duration(seconds: 2));
  });

  test('project templates apply canvas, transitions and overlays', () {
    final store = TemplateStore(persist: false);
    final tpl = store.builtin.firstWhere((t) => t.id == 'tpl_tiktok');
    final c = _seeded();
    c.applyProjectTemplate(tpl);
    expect(c.project.aspectRatio, closeTo(9 / 16, .001));
    expect(c.project.clips.every((x) => x.transition == EditorTransition.glitch),
        isTrue);
    expect(c.project.clips.first.filter.preset, 'vivid');
    expect(c.project.overlays.length, greaterThan(2));
  });

  test('user templates survive a JSON round trip', () {
    final c = _seeded();
    final overlay = c.project.overlays.first;
    final t = EditorTemplate.fromText('mine', overlay);
    final back = EditorTemplate.tryDecode(t.encode())!;
    final o2 = overlayFromJson(back.data, id: 'x')!;
    expect(o2.label, overlay.label);
    expect(o2.style.fontFamily, overlay.style.fontFamily);
  });

  test('all built-in templates and text templates are valid', () {
    final store = TemplateStore(persist: false);
    for (final t in store.builtin) {
      for (final raw in t.data['overlays'] as List) {
        expect(overlayFromJson(Map<String, dynamic>.from(raw as Map), id: 'x'),
            isNotNull);
      }
    }
    expect(textTemplates.where((t) => t.category == 'Animated').length,
        greaterThanOrEqualTo(8));
  });
}

void visibilityTests() {
  testWidgets('text overlay is visible (opacity > 0) when paused at its start',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _seeded();
    controller.seek(controller.selectedOverlay?.start ?? Duration.zero);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoEditorStudioScreen(controller: controller, store: TemplateStore(persist: false))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final text = find.text('TRAVEL VLOG');
    expect(text, findsOneWidget);
    final opacity = tester
        .widgetList<Opacity>(find.ancestor(of: text, matching: find.byType(Opacity)))
        .map((o) => o.opacity)
        .reduce((a, b) => a * b);
    expect(opacity, greaterThan(.9));
  });

  testWidgets('transition frame is built while playhead is inside it',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _seeded();
    controller.selectClip(controller.project.clips.last.id);
    controller.updateSelectedTransition(EditorTransition.slideLeft);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoEditorStudioScreen(controller: controller, store: TemplateStore(persist: false))),
    ));
    controller.seek(const Duration(seconds: 5, milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.activeTransition?.type, EditorTransition.slideLeft);
    expect(find.text('Slide left'), findsWidgets);
  });
}
