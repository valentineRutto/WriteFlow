enum ScannedContentType { text, table, figure, formula }

class ScannedContentBlock {
  const ScannedContentBlock({
    required this.type,
    required this.text,
    this.confidence = 0,
  });

  final ScannedContentType type;
  final String text;
  final double confidence;
}

class ScannedPage {
  const ScannedPage({
    required this.number,
    required this.text,
    required this.confidence,
    this.rawText,
    this.imageUri,
    this.aiEngine,
    this.lowConfidencePhrases = const [],
    this.contentBlocks = const [],
  });

  final int number;
  final String text;
  final String? rawText;
  final String? imageUri;
  final String? aiEngine;
  final double confidence;
  final List<String> lowConfidencePhrases;
  final List<ScannedContentBlock> contentBlocks;

  ScannedPage copyWith({
    int? number,
    String? text,
    String? rawText,
    String? imageUri,
    String? aiEngine,
    double? confidence,
    List<String>? lowConfidencePhrases,
    List<ScannedContentBlock>? contentBlocks,
  }) {
    return ScannedPage(
      number: number ?? this.number,
      text: text ?? this.text,
      rawText: rawText ?? this.rawText,
      imageUri: imageUri ?? this.imageUri,
      aiEngine: aiEngine ?? this.aiEngine,
      confidence: confidence ?? this.confidence,
      lowConfidencePhrases: lowConfidencePhrases ?? this.lowConfidencePhrases,
      contentBlocks: contentBlocks ?? this.contentBlocks,
    );
  }
}

class ScannedDocument {
  const ScannedDocument({
    required this.title,
    required this.pages,
    this.pdfUri,
    this.engine = 'Demo scanner',
  });

  final String title;
  final List<ScannedPage> pages;
  final String? pdfUri;
  final String engine;

  double get overallConfidence {
    if (pages.isEmpty) {
      return 0;
    }

    final total = pages.fold<double>(0, (sum, page) => sum + page.confidence);
    return total / pages.length;
  }

  ScannedDocument copyWith({
    String? title,
    List<ScannedPage>? pages,
    String? pdfUri,
    String? engine,
  }) {
    return ScannedDocument(
      title: title ?? this.title,
      pages: pages ?? this.pages,
      pdfUri: pdfUri ?? this.pdfUri,
      engine: engine ?? this.engine,
    );
  }
}
