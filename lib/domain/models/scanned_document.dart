class ScannedPage {
  const ScannedPage({
    required this.number,
    required this.text,
    required this.confidence,
    this.lowConfidencePhrases = const [],
  });

  final int number;
  final String text;
  final double confidence;
  final List<String> lowConfidencePhrases;
}

class ScannedDocument {
  const ScannedDocument({required this.title, required this.pages});

  final String title;
  final List<ScannedPage> pages;

  double get overallConfidence {
    if (pages.isEmpty) {
      return 0;
    }

    final total = pages.fold<double>(0, (sum, page) => sum + page.confidence);
    return total / pages.length;
  }
}
