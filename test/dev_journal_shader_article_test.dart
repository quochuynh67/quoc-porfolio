import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/journal/dev_journal_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openShaderArticle(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: DevJournalPage()),
    );
    await tester.enterText(
      find.byType(TextField).first,
      'Thực hành GL Transition',
    );
    await tester.pump();
    await tester.tap(find.text(
      'Thực hành GL Transition: biến ảnh A thành ảnh B bằng GPU',
    ));
    await tester.pump();
  }

  testWidgets('opens the interactive shader tutorial on desktop',
      (tester) async {
    await openShaderArticle(tester, const Size(1200, 900));

    expect(find.text('Interactive GL transition lab'), findsOneWidget);
    expect(find.textContaining('0% = ảnh A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shader tutorial fits a compact mobile viewport', (tester) async {
    await openShaderArticle(tester, const Size(390, 780));

    expect(find.text('Interactive GL transition lab'), findsOneWidget);
    expect(find.text('GPU LIVE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
