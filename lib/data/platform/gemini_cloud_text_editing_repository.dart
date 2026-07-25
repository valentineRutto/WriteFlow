import 'dart:convert';
import 'dart:io';

import '../../domain/repositories/text_editing_repository.dart';
import 'gemma_text_editing_repository.dart';

class GeminiCloudTextEditingRepository implements TextEditingRepository {
  const GeminiCloudTextEditingRepository({
    this.apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
    this.model = 'gemini-2.5-flash',
  });

  final String apiKey;
  final String model;

  @override
  Future<String> improveHandwritingText(String text) async {
    final sourceText = text.trim();
    if (sourceText.isEmpty) {
      return sourceText;
    }
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'Gemini cloud fallback is not configured. '
        'Run with --dart-define=GEMINI_API_KEY=your_key.',
      );
    }

    final client = HttpClient();
    try {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
      );
      final request = await client.postUrl(uri);
      request.headers
        ..contentType = ContentType.json
        ..set('x-goog-api-key', apiKey);
      request.write(
        jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': buildOcrCleanupRequest(sourceText)},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 2048},
        }),
      );

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Gemini request failed (${response.statusCode}): '
          '${_cloudErrorMessage(body)}',
          uri: uri,
        );
      }

      final cleaned = cleanGemmaResponse(_cloudResponseText(body));
      if (cleaned.isEmpty) {
        throw StateError('Gemini returned an empty cleaned text response.');
      }
      return cleaned;
    } finally {
      client.close(force: true);
    }
  }
}

String _cloudResponseText(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    return '';
  }
  final candidates = decoded['candidates'];
  if (candidates is! List || candidates.isEmpty || candidates.first is! Map) {
    return '';
  }
  final content = (candidates.first as Map)['content'];
  if (content is! Map) {
    return '';
  }
  final parts = content['parts'];
  if (parts is! List) {
    return '';
  }
  return parts
      .whereType<Map>()
      .map((part) => part['text'])
      .whereType<String>()
      .join()
      .trim();
}

String _cloudErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['error'] is Map) {
      final message = (decoded['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
  } on FormatException {
    // Use the raw response below.
  }
  return body.trim().isEmpty ? 'No error details returned.' : body.trim();
}
