import 'package:flutter_gemma/flutter_gemma.dart';

import '../../domain/models/gemma_model_option.dart';
import '../../domain/repositories/gemma_model_repository.dart';

const gemmaModelCatalog = <GemmaModelOption>[
  GemmaModelOption(
    id: 'gemma3-270m-it-q8.task',
    name: 'Gemma 3 270M',
    description: 'Fastest option for OCR cleanup on lower-memory phones.',
    sizeLabel: 'Compact',
    url:
        'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.task',
  ),
  GemmaModelOption(
    id: 'gemma3-1b-it-int4.task',
    name: 'Gemma 3 1B',
    description: 'Better text quality with higher memory and storage use.',
    sizeLabel: 'Balanced',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
  ),
];

class FlutterGemmaModelRepository implements GemmaModelRepository {
  FlutterGemmaModelRepository({this.onModelChanged});

  final void Function()? onModelChanged;

  @override
  Future<List<GemmaModelState>> loadModels() async {
    final active =
        FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
    final activeFilename = active?.files.firstOrNull?.filename;
    return Future.wait(
      gemmaModelCatalog.map((option) async {
        return GemmaModelState(
          option: option,
          isInstalled: await FlutterGemma.isModelInstalled(option.id),
          isActive: activeFilename == option.id,
        );
      }),
    );
  }

  @override
  Future<void> downloadAndActivate(
    GemmaModelOption model, {
    required void Function(int progress) onProgress,
  }) async {
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(model.url, foreground: true)
        .withProgress(onProgress)
        .install();
    onModelChanged?.call();
  }
}
