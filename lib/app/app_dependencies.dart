import '../data/repositories/demo_library_repository.dart';
import '../data/repositories/demo_scan_repository.dart';
import '../data/repositories/native_scan_repository.dart';
import '../data/repositories/local_library_repository.dart';
import '../data/repositories/gemma_model_repository.dart';
import '../data/platform/gemma_text_editing_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/gemma_model_repository.dart';
import '../domain/repositories/scan_repository.dart';
import '../domain/repositories/text_editing_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.scanRepository,
    required this.libraryRepository,
    required this.textEditingRepository,
    required this.gemmaModelRepository,
  });

  factory AppDependencies.production() {
    final textEditingRepository = GemmaTextEditingRepository();
    final libraryRepository = LocalLibraryRepository();
    final gemmaModelRepository = FlutterGemmaModelRepository(
      onModelChanged: textEditingRepository.resetModel,
    );

    return AppDependencies(
      scanRepository: NativeScanRepository(
        textEditingRepository: textEditingRepository,
      ),
      libraryRepository: libraryRepository,
      textEditingRepository: textEditingRepository,
      gemmaModelRepository: gemmaModelRepository,
    );
  }

  factory AppDependencies.demo() {
    return AppDependencies(
      scanRepository: const DemoScanRepository(),
      libraryRepository: const DemoLibraryRepository(),
      textEditingRepository: GemmaTextEditingRepository(),
      gemmaModelRepository: FlutterGemmaModelRepository(),
    );
  }

  final ScanRepository scanRepository;
  final LibraryRepository libraryRepository;
  final TextEditingRepository textEditingRepository;
  final GemmaModelRepository gemmaModelRepository;
}
