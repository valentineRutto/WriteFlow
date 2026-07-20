import '../data/repositories/demo_library_repository.dart';
import '../data/repositories/demo_scan_repository.dart';
import '../data/repositories/native_scan_repository.dart';
import '../data/repositories/local_library_repository.dart';
import '../data/platform/gemma_text_editing_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/scan_repository.dart';
import '../domain/repositories/text_editing_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.scanRepository,
    required this.libraryRepository,
    required this.textEditingRepository,
  });

  factory AppDependencies.production() {
    final textEditingRepository = GemmaTextEditingRepository();
    final libraryRepository = LocalLibraryRepository();

    return AppDependencies(
      scanRepository: NativeScanRepository(
        textEditingRepository: textEditingRepository,
      ),
      libraryRepository: libraryRepository,
      textEditingRepository: textEditingRepository,
    );
  }

  factory AppDependencies.demo() {
    return AppDependencies(
      scanRepository: const DemoScanRepository(),
      libraryRepository: const DemoLibraryRepository(),
      textEditingRepository: GemmaTextEditingRepository(),
    );
  }

  final ScanRepository scanRepository;
  final LibraryRepository libraryRepository;
  final TextEditingRepository textEditingRepository;
}
