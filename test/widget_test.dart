import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inkdoc/main.dart';

void main() {
  testWidgets('navigates between InkDoc screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const InkDocApp());

    expect(find.text('InkDoc'), findsOneWidget);
    expect(find.text('Tap to scan'), findsOneWidget);

    await tester.tap(find.text('Tap to scan'));
    await tester.pumpAndSettle();

    expect(find.text('Diary entry - 1 page'), findsOneWidget);
    expect(find.textContaining('The morning light'), findsOneWidget);
    expect(find.textContaining('Demo fallback scanner'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Export as'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('EPUB'));
    await tester.pump();

    expect(find.text('Export EPUB'), findsOneWidget);

    await tester.tap(find.text('My library'));
    await tester.pump();

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('Q1 business ledger'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.text('Q1 business ledger'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pump();

    expect(find.text('Diary - March 1987'), findsOneWidget);
    expect(find.text("Grandma's recipe book"), findsOneWidget);

    await tester.tap(find.text('Diary - March 1987'));
    await tester.pumpAndSettle();

    expect(find.text('Diary - March 1987 - 3 pages'), findsOneWidget);
    expect(find.textContaining('opened from your library'), findsOneWidget);
    expect(find.text('Export as'), findsOneWidget);
  });

  testWidgets('edits recognised text from the preview header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const InkDocApp());

    await tester.tap(find.text('Tap to scan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit text').first);
    await tester.pumpAndSettle();

    expect(find.text('Edit recognised text'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.getSize(find.byType(Dialog)), const Size(430, 920));

    await tester.enterText(
      find.byType(EditableText).last,
      'Corrected handwritten note',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Corrected handwritten note'), findsOneWidget);
    expect(find.textContaining('The morning light'), findsNothing);
  });

  testWidgets('adds and edits document types from the home screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const InkDocApp());

    await tester.tap(find.byTooltip('Add document type'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Add document type'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'Letters');
    await tester.enterText(find.byType(EditableText).at(1), 'Mail & drafts');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Letters'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit document type'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Edit document type'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'Client letters');
    await tester.enterText(find.byType(EditableText).at(1), 'Signed drafts');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Client letters'), findsOneWidget);
    expect(find.text('Letters'), findsNothing);
  });
}
