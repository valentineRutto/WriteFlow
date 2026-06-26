import '../../domain/repositories/text_editing_repository.dart';

class LocalTextEditingRepository implements TextEditingRepository {
  const LocalTextEditingRepository();

  @override
  Future<String> improveHandwritingText(String text) async {
    return cleanRecognizedText(text);
  }
}

String cleanRecognizedText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final normalizedWhitespace = trimmed
      .split('\n')
      .map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((line) => line.isNotEmpty)
      .join('\n');

  final sentenceFixed = normalizedWhitespace.replaceAllMapped(
    RegExp(r'(^|[.!?]\s+)([a-z])'),
    (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
  );

  return sentenceFixed
      .replaceAll(' ,', ',')
      .replaceAll(' .', '.')
      .replaceAll(' ?', '?')
      .replaceAll(' !', '!');
}
