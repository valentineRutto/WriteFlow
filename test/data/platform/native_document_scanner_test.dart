import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/data/platform/native_document_scanner.dart';
import 'package:inkdoc/domain/models/scanned_document.dart';

void main() {
  test('parses tables figures and formulas from the native scanner', () {
    final result = NativeScanResult.fromMap({
      'engine': 'ML Kit',
      'pages': [
        <Object?, Object?>{
          'number': 1,
          'text': 'Item\tAmount\nBooks\t2\n\nFigure 1: Results\n\nx² + y² = z²',
          'confidence': 0.88,
          'contentBlocks': [
            <Object?, Object?>{
              'type': 'table',
              'text': 'Item\tAmount\nBooks\t2',
              'confidence': 0.88,
            },
            <Object?, Object?>{
              'type': 'figure',
              'text': 'Figure 1: Results',
              'confidence': 0.88,
            },
            <Object?, Object?>{
              'type': 'formula',
              'text': 'x² + y² = z²',
              'confidence': 0.88,
            },
          ],
        },
      ],
    });

    expect(result.pages, hasLength(1));
    expect(result.pages.single.contentBlocks.map((block) => block.type), [
      ScannedContentType.table,
      ScannedContentType.figure,
      ScannedContentType.formula,
    ]);
  });

  test('unknown native block types safely fall back to text', () {
    final result = NativeScanResult.fromMap({
      'pages': [
        <Object?, Object?>{
          'contentBlocks': [
            <Object?, Object?>{'type': 'unknown', 'text': 'A paragraph'},
          ],
        },
      ],
    });

    expect(
      result.pages.single.contentBlocks.single.type,
      ScannedContentType.text,
    );
  });
}
