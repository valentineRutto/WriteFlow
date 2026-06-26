import '../../domain/models/scanned_document.dart';
import '../../domain/repositories/scan_repository.dart';

class DemoScanRepository implements ScanRepository {
  const DemoScanRepository();

  @override
  Future<ScannedDocument> scan({
    required int documentTypeIndex,
    required bool batchMode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final pageCount = batchMode ? 3 : 1;
    final pages = List.generate(
      pageCount,
      (index) => ScannedPage(
        number: index + 1,
        text:
            'March 14th, 1987\n'
            'The morning light came through the curtains differently today. '
            'I sat with my tea and watched the garden wake up slowly, each '
            'leaf catching what little warmth there was. Mother called from '
            'Nakuru - she sounds well.',
        confidence: 0.94 - (index * 0.01),
        lowConfidencePhrases: const ['March 14th, 1987', 'Mother called'],
      ),
    );

    return ScannedDocument(
      title: 'Diary entry',
      pages: pages,
      engine: 'Demo fallback scanner',
    );
  }
}
