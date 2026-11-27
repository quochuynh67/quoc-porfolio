import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/application/video_editor_controller.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/application/template_store.dart';
import 'dart:io';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/shader_catalog.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/editor_catalog.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/editor_template.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/editor_motion.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/video_editor_project.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/editor_timeline.dart';
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
  timelineDragTests();
  clipTests();
  shaderTests();

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
        home: Scaffold(
            body: VideoEditorStudioScreen(
                controller: controller, store: TemplateStore(persist: false))),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      // Walk through every tool tab.
      for (final label in [
        'Text',
        'Stickers',
        'Transitions',
        'Filters',
        'Templates',
        'Analyze',
        'Edit'
      ]) {
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
        inPoint: const Duration(seconds: 2),
        outPoint: const Duration(seconds: 8));
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
    expect(
        c.project.clips.every((x) => x.transition == EditorTransition.glitch),
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
      home: Scaffold(
          body: VideoEditorStudioScreen(
              controller: controller, store: TemplateStore(persist: false))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final text = find.text('TRAVEL VLOG');
    expect(text, findsOneWidget);
    final opacity = tester
        .widgetList<Opacity>(
            find.ancestor(of: text, matching: find.byType(Opacity)))
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
      home: Scaffold(
          body: VideoEditorStudioScreen(
              controller: controller, store: TemplateStore(persist: false))),
    ));
    controller.seek(const Duration(seconds: 5, milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.activeTransition?.type, EditorTransition.slideLeft);
    expect(find.text('Slide left'), findsWidgets);
  });
}

void timelineDragTests() {
  testWidgets('dragging an overlay block moves it; its right edge resizes it',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _seeded();
    controller.seek(Duration.zero);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: VideoEditorStudioScreen(
              controller: controller, store: TemplateStore(persist: false))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final overlay = controller.project.overlays
        .firstWhere((o) => o.type == EditorOverlayType.text);
    final block = find.descendant(
        of: find.byType(EditorTimeline), matching: find.text(overlay.label));
    expect(block, findsOneWidget);
    controller.selectOverlay(overlay.id);
    await tester.pump();

    final startBefore = controller.selectedOverlay!.start;
    await tester.drag(block, const Offset(80, 0));
    await tester.pump();
    final moved = controller.selectedOverlay!.start;
    expect(moved, greaterThan(startBefore));

    final lenBefore = controller.selectedOverlay!.duration;
    final rect = tester.getRect(
        find.ancestor(of: block, matching: find.byType(Positioned)).first);
    await tester.dragFrom(
        rect.centerRight - const Offset(4, 0), const Offset(60, 0));
    await tester.pump();
    expect(controller.selectedOverlay!.duration, greaterThan(lenBefore));
    expect(controller.selectedOverlay!.start, moved);
  });
}

void clipTests() {
  test('clips added in the same instant get distinct ids', () {
    final c = VideoEditorController();
    for (var i = 0; i < 6; i++) {
      c.addClip(name: 'p$i.png', type: EditorAssetType.image, bytes: _png);
    }
    final ids = c.project.clips.map((e) => e.id).toSet();
    expect(ids.length, 6);
  });

  testWidgets('dragging a clip past its neighbour reorders it', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = VideoEditorController();
    for (var i = 0; i < 3; i++) {
      c.addClip(name: 'p$i.png', type: EditorAssetType.image, bytes: _png);
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: VideoEditorStudioScreen(
              controller: c, store: TemplateStore(persist: false))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final first = find.descendant(
        of: find.byType(EditorTimeline), matching: find.text('p0.png'));
    await tester.drag(first, const Offset(300, 0));
    await tester.pump();
    expect(c.project.clips.map((e) => e.name).toList()[0], isNot('p0.png'));
  });
}

void shaderTests() {
  test('every catalogued shader has its source file and ids are unique', () {
    final ids = <String>{};
    for (final s in shaderCatalog) {
      expect(ids.add(s.id), isTrue, reason: 'duplicate ${s.id}');
      expect(File(s.asset).existsSync(), isTrue, reason: s.asset);
    }
    expect(shaderById('flag_vn')?.name, 'Việt Nam');
    expect(shaderCatalog.first.category, flagsCategory);
    for (final id in featuredShaderIds) {
      expect(shaderById(id), isNotNull, reason: id);
    }
  });

  test('a shader transition keeps its shader id for preview and export', () {
    final c = _seeded();
    c.selectClip(c.project.clips[1].id);
    c.updateSelectedTransition(EditorTransition.shader, shaderId: 'flag_vn');
    expect(c.project.clips[1].shaderId, 'flag_vn');
    c.seek(const Duration(seconds: 5, milliseconds: 300));
    expect(c.activeTransition!.shaderId, 'flag_vn');
    c.updateSelectedTransition(EditorTransition.fade);
    expect(c.project.clips[1].shaderId, isNull);
  });

  testWidgets('shader browser lists flags and selects Viet Nam',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _seeded();
    c.selectClip(c.project.clips[1].id);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: VideoEditorStudioScreen(
              controller: c, store: TemplateStore(persist: false))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final tab = find.text('Transitions').first;
    await tester.ensureVisible(tab);
    await tester.tap(tab, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Applies to the cut into'), findsOneWidget);
    final browse = find.textContaining('Browse all');
    final anchor =
        tester.getCenter(find.textContaining('Applies to the cut into'));
    for (var i = 0; i < 12 && browse.evaluate().isEmpty; i++) {
      await tester.dragFrom(anchor, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(browse);
    await tester.tap(browse);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Shader transitions'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'vi');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Việt Nam').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.project.clips[1].transition, EditorTransition.shader);
    expect(c.project.clips[1].shaderId, 'flag_vn');
  });
}
