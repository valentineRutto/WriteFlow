import 'package:flutter/services.dart';

class NativeDocumentScanner {
  const NativeDocumentScanner({
    this.channel = const MethodChannel('inkdoc/on_device_ai'),
  });

  final MethodChannel channel;

  Future<NativeScanResult> scanDocument({required int pageLimit}) async {
    final result = await channel
        .invokeMapMethod<String, Object?>('scanDocument', {
          'pageLimit': pageLimit,
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

    return NativeScanResult.fromMap(result);
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
  });

  factory NativeScannedPage.fromMap(Map<Object?, Object?> map) {
    final rawPhrases = map['lowConfidencePhrases'];
    final lowConfidencePhrases = rawPhrases is List
        ? rawPhrases.whereType<String>().toList(growable: false)
        : const <String>[];

    return NativeScannedPage(
      number: map['number'] as int? ?? 1,
      text: map['text'] as String? ?? '',
      rawText: map['rawText'] as String?,
      imageUri: map['imageUri'] as String?,
      aiEngine: map['aiEngine'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      lowConfidencePhrases: lowConfidencePhrases,
    );
  }

  final int number;
  final String text;
  final String? rawText;
  final String? imageUri;
  final String? aiEngine;
  final double confidence;
  final List<String> lowConfidencePhrases;
}
