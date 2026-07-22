import 'package:flutter_gemma/flutter_gemma.dart';

import '../../domain/repositories/text_editing_repository.dart';

const ocrCleanupPrompt =
    'Proofread and improve this extracted OCR text.\n'
    'Keep the meaning, fix spelling/grammar, and return only the improved text.';

class GemmaTextEditingRepository implements TextEditingRepository {
  GemmaTextEditingRepository({this.maxTokens = 2048});

  final int maxTokens;
  InferenceModel? _model;

  void resetModel() => _model = null;

  @override
  Future<String> improveHandwritingText(String text) async {
    final sourceText = text.trim();
    if (sourceText.isEmpty) {
      return sourceText;
    }

    final model = _model ??= await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
    );
    final session = await model.createSession(temperature: 0.2, topK: 1);

    try {
      await session.addQueryChunk(
        Message.text(text: buildOcrCleanupRequest(sourceText), isUser: true),
      );

      final response = cleanGemmaResponse(await session.getResponse());
      if (response.isEmpty) {
        throw StateError('Gemma returned an empty cleaned text response.');
      }
      return response;
    } finally {
      await session.close();
    }
  }
}

String buildOcrCleanupRequest(String text) => '$ocrCleanupPrompt\n\n$text';

String cleanGemmaResponse(String response) {
  final trimmed = response.trim();
  final fenced = RegExp(
    r'^```(?:text)?\s*([\s\S]*?)\s*```$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  return (fenced?.group(1) ?? trimmed).trim();
}
