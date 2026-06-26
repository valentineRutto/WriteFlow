import '../data/repositories/demo_library_repository.dart';
import '../data/repositories/demo_scan_repository.dart';
import '../data/repositories/native_scan_repository.dart';
import '../data/platform/native_text_editing_repository.dart';
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
    const textEditingRepository = NativeTextEditingRepository();

    return const AppDependencies(
      scanRepository: NativeScanRepository(
        textEditingRepository: textEditingRepository,
      ),
      libraryRepository: DemoLibraryRepository(),
      textEditingRepository: textEditingRepository,
    );
  }

  factory AppDependencies.demo() {
    return const AppDependencies(
      scanRepository: DemoScanRepository(),
      libraryRepository: DemoLibraryRepository(),
      textEditingRepository: NativeTextEditingRepository(),
    );
  }

  final ScanRepository scanRepository;
  final LibraryRepository libraryRepository;
  final TextEditingRepository textEditingRepository;
}
