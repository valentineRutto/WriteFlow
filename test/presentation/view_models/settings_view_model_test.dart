import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/domain/models/gemma_model_option.dart';
import 'package:inkdoc/domain/repositories/gemma_model_repository.dart';
import 'package:inkdoc/presentation/view_models/settings_view_model.dart';

void main() {
  test('downloads a model, reports progress, and marks it active', () async {
    final repository = _FakeGemmaModelRepository();
    final viewModel = SettingsViewModel(repository: repository);

    await viewModel.load();
    await viewModel.select(_model);

    expect(viewModel.progress, 100);
    expect(viewModel.busyModelId, isNull);
    expect(viewModel.models.single.isInstalled, isTrue);
    expect(viewModel.models.single.isActive, isTrue);
  });
}

const _model = GemmaModelOption(
  id: 'test.task',
  name: 'Test Gemma',
  description: 'Test model',
  sizeLabel: 'Compact',
  url: 'https://example.com/test.task',
  minimumRamGb: 4,
  requiredStorageGb: 1,
);

class _FakeGemmaModelRepository implements GemmaModelRepository {
  bool installed = false;

  @override
  Future<DeviceCapabilities> loadDeviceCapabilities() async =>
      const DeviceCapabilities(
        platform: 'Android',
        osVersion: 'Android 16',
        totalRamGb: 8,
        freeStorageGb: 20,
        architecture: 'arm64-v8a',
      );

  @override
  Future<List<GemmaModelState>> loadModels() async => [
    GemmaModelState(
      option: _model,
      isInstalled: installed,
      isActive: installed,
    ),
  ];

  @override
  Future<void> downloadAndActivate(
    GemmaModelOption model, {
    required void Function(int progress) onProgress,
  }) async {
    onProgress(35);
    onProgress(100);
    installed = true;
  }
}
