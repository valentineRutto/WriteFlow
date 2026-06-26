import 'dart:ui';

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
}
