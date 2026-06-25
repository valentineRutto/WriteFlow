import 'package:flutter_test/flutter_test.dart';
import 'package:writeflow/domain/models/library_document.dart';
import 'package:writeflow/domain/repositories/library_repository.dart';
import 'package:writeflow/presentation/view_models/library_view_model.dart';

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
