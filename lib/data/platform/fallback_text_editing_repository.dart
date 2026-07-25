import '../../domain/repositories/text_editing_repository.dart';

abstract interface class TextEditingEngineReporter {
  String get lastEngine;
}

class FallbackTextEditingRepository
    implements TextEditingRepository, TextEditingEngineReporter {
  FallbackTextEditingRepository({
    required this.primary,
    required this.fallback,
    this.primaryEngine = 'Gemma on-device text cleanup',
    this.fallbackEngine = 'Gemini cloud text cleanup',
  });

  final TextEditingRepository primary;
  final TextEditingRepository fallback;
  final String primaryEngine;
  final String fallbackEngine;

  @override
  String lastEngine = '';

  @override
  Future<String> improveHandwritingText(String text) async {
    try {
      final result = await primary.improveHandwritingText(text);
      lastEngine = primaryEngine;
      return result;
    } on Object catch (primaryError) {
      try {
        final result = await fallback.improveHandwritingText(text);
        lastEngine = fallbackEngine;
        return result;
      } on Object catch (fallbackError) {
        throw TextEditingFallbackException(primaryError, fallbackError);
      }
    }
  }
}

class TextEditingFallbackException implements Exception {
  const TextEditingFallbackException(this.primaryError, this.fallbackError);

  final Object primaryError;
  final Object fallbackError;

  @override
  String toString() =>
      'Could not clean text on-device or with Gemini cloud. '
      'On-device: $primaryError Cloud: $fallbackError';
}
