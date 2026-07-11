import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/domain/models/library_document.dart';
import 'package:inkdoc/domain/repositories/library_repository.dart';
import 'package:inkdoc/presentation/view_models/library_view_model.dart';

void main() {
  test('library filters repository documents by title or category', () async {
    final viewModel = LibraryViewModel(
      repository: const _FakeLibraryRepository(),
    );

    await viewModel.load();
    viewModel.search('poetry');

    expect(viewModel.documents, hasLength(1));
    expect(viewModel.documents.single.title, 'Collected poems');
  });

  test('library paginates and resets to page one after search', () async {
    final viewModel = LibraryViewModel(
      repository: const _FakeLibraryRepository(),
      pageSize: 1,
    );
    await viewModel.load();

    expect(viewModel.totalPages, 2);
    expect(viewModel.documents.single.title, 'Daily journal');

    viewModel.nextPage();
    expect(viewModel.currentPage, 2);
    expect(viewModel.documents.single.title, 'Collected poems');

    viewModel.search('diary');
    expect(viewModel.currentPage, 1);
    expect(viewModel.totalPages, 1);
    expect(viewModel.documents.single.title, 'Daily journal');
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  const _FakeLibraryRepository();

  @override
  Future<List<LibraryDocument>> loadDocuments() async {
    return const [
      LibraryDocument(
        title: 'Daily journal',
        meta: '1 page',
        category: 'Diary',
      ),
      LibraryDocument(
        title: 'Collected poems',
        meta: '4 pages',
        category: 'Poetry',
      ),
    ];
  }
}
