import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/data/platform/gemma_text_editing_repository.dart';

void main() {
  test('builds the OCR cleanup request with the required prompt', () {
    expect(
      buildOcrCleanupRequest('ths is OCR txt.'),
      '$ocrCleanupPrompt\n\nths is OCR txt.',
    );
  });

  test('removes an unnecessary markdown fence from the Gemma response', () {
    expect(
      cleanGemmaResponse('```text\nThis is OCR text.\n```'),
      'This is OCR text.',
    );
  });
}
