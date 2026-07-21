import 'package:flutter/services.dart';

import '../../domain/models/scanned_document.dart';

class NativeDocumentScanner {
  const NativeDocumentScanner({
    this.channel = const MethodChannel('inkdoc/on_device_ai'),
  });

  final MethodChannel channel;

  Future<NativeScanResult> scanDocument({
    required int pageLimit,
    required bool batchMode,
  }) async {
    if (pageLimit < 1) {
      throw ArgumentError.value(pageLimit, 'pageLimit', 'Must be at least 1');
    }
    final result = await channel
        .invokeMapMethod<String, Object?>('scanDocument', {
          'pageLimit': pageLimit,
          'batchMode': batchMode,
          'output': 'jpeg_pdf',
          'ocr': 'handwriting',
          'postprocess': 'on_device_ai',
        });

    if (result == null) {
      throw PlatformException(
        code: 'NO_SCAN_RESULT',
        message: 'Native scanner did not return a result.',
      );
    }

    final scanResult = NativeScanResult.fromMap(result);
    if (scanResult.pages.length <= pageLimit) return scanResult;
    return NativeScanResult(
      pages: scanResult.pages.take(pageLimit).toList(growable: false),
      engine: scanResult.engine,
      pdfUri: scanResult.pdfUri,
    );
  }
}

class NativeScanResult {
  const NativeScanResult({
    required this.pages,
    required this.engine,
    this.pdfUri,
  });

  factory NativeScanResult.fromMap(Map<String, Object?> map) {
    final rawPages = map['pages'];
    final pages = rawPages is List
        ? rawPages
              .whereType<Map<Object?, Object?>>()
              .map(NativeScannedPage.fromMap)
              .toList(growable: false)
        : const <NativeScannedPage>[];

    return NativeScanResult(
      pages: pages,
      pdfUri: map['pdfUri'] as String?,
      engine: map['engine'] as String? ?? 'Native on-device scan pipeline',
    );
  }

  final List<NativeScannedPage> pages;
  final String? pdfUri;
  final String engine;
}

class NativeScannedPage {
  const NativeScannedPage({
    required this.number,
    required this.text,
    required this.confidence,
    this.rawText,
    this.imageUri,
    this.aiEngine,
    this.lowConfidencePhrases = const [],
    this.contentBlocks = const [],
  });

  factory NativeScannedPage.fromMap(Map<Object?, Object?> map) {
    final rawPhrases = map['lowConfidencePhrases'];
    final lowConfidencePhrases = rawPhrases is List
        ? rawPhrases.whereType<String>().toList(growable: false)
        : const <String>[];
    final rawBlocks = map['contentBlocks'];
    final contentBlocks = rawBlocks is List
        ? rawBlocks
              .whereType<Map<Object?, Object?>>()
              .map(_contentBlockFromMap)
              .toList(growable: false)
        : const <ScannedContentBlock>[];

    return NativeScannedPage(
      number: map['number'] as int? ?? 1,
      text: map['text'] as String? ?? '',
      rawText: map['rawText'] as String?,
      imageUri: map['imageUri'] as String?,
      aiEngine: map['aiEngine'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      lowConfidencePhrases: lowConfidencePhrases,
      contentBlocks: contentBlocks,
    );
  }

  final int number;
  final String text;
  final String? rawText;
  final String? imageUri;
  final String? aiEngine;
  final double confidence;
  final List<String> lowConfidencePhrases;
  final List<ScannedContentBlock> contentBlocks;
}

ScannedContentBlock _contentBlockFromMap(Map<Object?, Object?> map) {
  final typeName = map['type'] as String? ?? 'text';
  final type = ScannedContentType.values.firstWhere(
    (value) => value.name == typeName,
    orElse: () => ScannedContentType.text,
  );
  return ScannedContentBlock(
    type: type,
    text: map['text'] as String? ?? '',
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
  );
}
