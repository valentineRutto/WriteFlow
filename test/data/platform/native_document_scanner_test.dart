import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/data/platform/native_document_scanner.dart';
import 'package:inkdoc/domain/models/scanned_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('passes batch settings and enforces the requested page limit', () async {
    const channel = MethodChannel('inkdoc/test_scanner');
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return {
            'pages': List.generate(
              4,
              (index) => <Object?, Object?>{
                'number': index + 1,
                'text': 'Page ${index + 1}',
              },
            ),
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final result = await const NativeDocumentScanner(
      channel: channel,
    ).scanDocument(pageLimit: 3, batchMode: true);

    expect(receivedCall?.method, 'scanDocument');
    expect(receivedCall?.arguments, containsPair('batchMode', true));
    expect(receivedCall?.arguments, containsPair('pageLimit', 3));
    expect(result.pages, hasLength(3));
    expect(result.pages.last.number, 3);
  });

  test('rejects an invalid page limit before opening the scanner', () {
    expect(
      () => const NativeDocumentScanner().scanDocument(
        pageLimit: 0,
        batchMode: false,
      ),
      throwsArgumentError,
    );
  });
}
