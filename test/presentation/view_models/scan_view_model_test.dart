import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/domain/models/scanned_document.dart';
import 'package:inkdoc/domain/repositories/scan_repository.dart';
import 'package:inkdoc/domain/models/library_document.dart';
import 'package:inkdoc/domain/repositories/library_repository.dart';
import 'package:inkdoc/presentation/view_models/scan_view_model.dart';

void main() {
  test('scan delegates selected options to the injected repository', () async {
    final repository = _FakeScanRepository();
    final libraryRepository = _FakeLibraryRepository();
    final viewModel = ScanViewModel(
      repository: repository,
      libraryRepository: libraryRepository,
    );

    viewModel.selectDocumentType(2);
    viewModel.setBatchMode(true);

    final document = await viewModel.scan();

    expect(repository.documentTypeIndex, 2);
    expect(repository.batchMode, isTrue);
    expect(document?.pages, hasLength(2));
    expect(libraryRepository.savedDocument, same(document));
    expect(viewModel.status, ScanStatus.completed);
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  ScannedDocument? savedDocument;

  @override
  Future<void> saveDocument(
    ScannedDocument document, {
    String? category,
  }) async {
    savedDocument = document;
  }

  @override
  Future<ScannedDocument?> loadDocument(int id) async => null;

  @override
  Future<List<LibraryDocument>> loadDocuments({
    int offset = 0,
    int limit = 20,
    String query = '',
  }) async => const [];
}

class _FakeScanRepository implements ScanRepository {
  int? documentTypeIndex;
  bool? batchMode;

  @override
  Future<ScannedDocument> scan({
    required int documentTypeIndex,
    required bool batchMode,
  }) async {
    this.documentTypeIndex = documentTypeIndex;
    this.batchMode = batchMode;

    return const ScannedDocument(
      title: 'Test document',
      pages: [
        ScannedPage(number: 1, text: 'First page', confidence: 0.9),
        ScannedPage(number: 2, text: 'Second page', confidence: 0.8),
      ],
    );
  }
}
