import 'package:flutter/services.dart';

import '../../domain/models/scanned_document.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/repositories/text_editing_repository.dart';
import '../platform/native_document_scanner.dart';
import 'demo_scan_repository.dart';

class NativeScanRepository implements ScanRepository {
  const NativeScanRepository({
    this.scanner = const NativeDocumentScanner(),
    this.textEditingRepository,
    this.fallback = const DemoScanRepository(),
  });

  final NativeDocumentScanner scanner;
  final TextEditingRepository? textEditingRepository;
  final ScanRepository fallback;

  @override
  Future<ScannedDocument> scan({
    required int documentTypeIndex,
    required bool batchMode,
  }) async {
    try {
      final scanResult = await scanner.scanDocument(
        pageLimit: batchMode ? 10 : 1,
      );

      if (scanResult.pages.isEmpty) {
        return fallback.scan(
          documentTypeIndex: documentTypeIndex,
          batchMode: batchMode,
        );
      }

      final pages = <ScannedPage>[];
      for (final page in scanResult.pages) {
        final improvedText = textEditingRepository == null
            ? page.text
            : await textEditingRepository!.improveHandwritingText(page.text);
        pages.add(
          ScannedPage(
            number: page.number,
            text: improvedText,
            rawText: page.rawText ?? page.text,
            imageUri: page.imageUri,
            aiEngine: page.aiEngine ?? 'On-device cleanup',
            confidence: page.confidence,
            lowConfidencePhrases: page.lowConfidencePhrases,
          ),
        );
      }

      return ScannedDocument(
        title: _titleFor(documentTypeIndex),
        pages: pages,
        pdfUri: scanResult.pdfUri,
        engine: scanResult.engine,
      );
    } on MissingPluginException {
      return fallback.scan(
        documentTypeIndex: documentTypeIndex,
        batchMode: batchMode,
      );
    } on PlatformException catch (error) {
      if (error.code == 'CANCELLED') {
        rethrow;
      }

      return fallback.scan(
        documentTypeIndex: documentTypeIndex,
        batchMode: batchMode,
      );
    }
  }

  String _titleFor(int documentTypeIndex) {
    return switch (documentTypeIndex) {
      0 => 'Diary entry',
      1 => 'Class notes',
      2 => 'Letter',
      3 => 'Meeting notes',
      _ => 'Scanned document',
    };
  }
}
