import '../data/repositories/demo_library_repository.dart';
import '../data/repositories/demo_scan_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/scan_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.scanRepository,
    required this.libraryRepository,
  });

  factory AppDependencies.demo() {
    return const AppDependencies(
      scanRepository: DemoScanRepository(),
      libraryRepository: DemoLibraryRepository(),
    );
  }

  final ScanRepository scanRepository;
  final LibraryRepository libraryRepository;
}
