import '../models/gemma_model_option.dart';

abstract interface class GemmaModelRepository {
  Future<List<GemmaModelState>> loadModels();

  Future<void> downloadAndActivate(
    GemmaModelOption model, {
    required void Function(int progress) onProgress,
  });
}
