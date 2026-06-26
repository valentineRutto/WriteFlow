class ScannedPage {
  const ScannedPage({
    required this.number,
    required this.text,
    required this.confidence,
    this.rawText,
    this.imageUri,
    this.aiEngine,
    this.lowConfidencePhrases = const [],
  });

  final int number;
  final String text;
  final String? rawText;
  final String? imageUri;
  final String? aiEngine;
  final double confidence;
  final List<String> lowConfidencePhrases;

  ScannedPage copyWith({
    int? number,
    String? text,
    String? rawText,
    String? imageUri,
    String? aiEngine,
    double? confidence,
    List<String>? lowConfidencePhrases,
  }) {
    return ScannedPage(
      number: number ?? this.number,
      text: text ?? this.text,
      rawText: rawText ?? this.rawText,
      imageUri: imageUri ?? this.imageUri,
      aiEngine: aiEngine ?? this.aiEngine,
      confidence: confidence ?? this.confidence,
      lowConfidencePhrases: lowConfidencePhrases ?? this.lowConfidencePhrases,
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
