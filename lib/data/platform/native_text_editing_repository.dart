import 'package:flutter/services.dart';

import '../../domain/repositories/text_editing_repository.dart';
import 'local_text_editing_repository.dart';

class NativeTextEditingRepository implements TextEditingRepository {
  const NativeTextEditingRepository({
    this.channel = const MethodChannel('writeflow/on_device_ai'),
    this.fallback = const LocalTextEditingRepository(),
  });

  final MethodChannel channel;
  final TextEditingRepository fallback;

  @override
  Future<String> improveHandwritingText(String text) async {
    try {
      final improvedText = await channel.invokeMethod<String>('improveText', {
        'text': text,
        'task': 'proofread_handwriting_ocr',
      });

      if (improvedText == null || improvedText.trim().isEmpty) {
        return fallback.improveHandwritingText(text);
      }

      return improvedText;
    } on MissingPluginException {
      return fallback.improveHandwritingText(text);
    } on PlatformException {
      return fallback.improveHandwritingText(text);
    }
  }
}
