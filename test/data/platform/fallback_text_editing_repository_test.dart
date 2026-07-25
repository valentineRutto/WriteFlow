import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/data/platform/fallback_text_editing_repository.dart';
import 'package:inkdoc/domain/repositories/text_editing_repository.dart';

void main() {
  test('uses the primary cleaner when it succeeds', () async {
    final repository = FallbackTextEditingRepository(
      primary: const _Cleaner('local result'),
      fallback: const _Cleaner('cloud result'),
    );

    expect(await repository.improveHandwritingText('source'), 'local result');
    expect(repository.lastEngine, 'Gemma on-device text cleanup');
  });

  test('uses Gemini cloud when the primary cleaner fails', () async {
    final repository = FallbackTextEditingRepository(
      primary: const _Cleaner.failure(),
      fallback: const _Cleaner('cloud result'),
    );

    expect(await repository.improveHandwritingText('source'), 'cloud result');
    expect(repository.lastEngine, 'Gemini cloud text cleanup');
  });

  test('reports both failures when neither cleaner succeeds', () async {
    final repository = FallbackTextEditingRepository(
      primary: const _Cleaner.failure(),
      fallback: const _Cleaner.failure(),
    );

    await expectLater(
      repository.improveHandwritingText('source'),
      throwsA(isA<TextEditingFallbackException>()),
    );
  });
}

class _Cleaner implements TextEditingRepository {
  const _Cleaner(this.result) : fails = false;
  const _Cleaner.failure() : result = '', fails = true;

  final String result;
  final bool fails;

  @override
  Future<String> improveHandwritingText(String text) async {
    if (fails) {
      throw StateError('failed');
    }
    return result;
  }
}
