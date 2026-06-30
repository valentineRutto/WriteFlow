import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:writeflow/main.dart';

void main() {
  testWidgets('navigates between Inkscribe screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const WriteFlowApp());

    expect(find.text('Inkscribe'), findsOneWidget);
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

    expect(find.text('Diary - March 1987'), findsOneWidget);
    expect(find.text("Grandma's recipe book"), findsOneWidget);
  });

  testWidgets('edits recognised text from the preview header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const WriteFlowApp());

    await tester.tap(find.text('Tap to scan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit text').first);
    await tester.pumpAndSettle();

    expect(find.text('Edit recognised text'), findsOneWidget);

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

    await tester.pumpWidget(const WriteFlowApp());

    await tester.tap(find.byTooltip('Add document type'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Add document type'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'Letters');
    await tester.enterText(find.byType(EditableText).at(1), 'Mail & drafts');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Letters'), findsOneWidget);
    expect(find.text('Mail & drafts'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit document type'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Edit document type'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'Client letters');
    await tester.enterText(find.byType(EditableText).at(1), 'Signed drafts');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Client letters'), findsOneWidget);
    expect(find.text('Signed drafts'), findsOneWidget);
    expect(find.text('Letters'), findsNothing);
  });
}
