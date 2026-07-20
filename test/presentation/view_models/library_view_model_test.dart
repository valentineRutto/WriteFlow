import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/domain/models/library_document.dart';
import 'package:inkdoc/domain/repositories/library_repository.dart';
import 'package:inkdoc/domain/models/scanned_document.dart';
import 'package:inkdoc/presentation/view_models/library_view_model.dart';

void main() {
  test('library filters repository documents by title or category', () async {
    final viewModel = LibraryViewModel(
      repository: const _FakeLibraryRepository(),
    );

    await viewModel.load();
    viewModel.search('poetry');
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(viewModel.documents, hasLength(1));
    expect(viewModel.documents.single.title, 'Collected poems');
  });

  test('library appends the next page and resets after search', () async {
    final viewModel = LibraryViewModel(
      repository: const _FakeLibraryRepository(),
      pageSize: 1,
    );
    await viewModel.load();

    expect(viewModel.documents.single.title, 'Daily journal');

    await viewModel.loadMore();
    expect(viewModel.documents, hasLength(2));
    expect(viewModel.documents.last.title, 'Collected poems');

    viewModel.search('diary');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(viewModel.documents.single.title, 'Daily journal');
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  const _FakeLibraryRepository();

  @override
  Future<List<LibraryDocument>> loadDocuments({
    int offset = 0,
    int limit = 20,
    String query = '',
  }) async {
    const documents = [
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
    final normalized = query.toLowerCase();
    final filtered = documents
        .where(
          (item) =>
              normalized.isEmpty ||
              item.title.toLowerCase().contains(normalized) ||
              item.category.toLowerCase().contains(normalized),
        )
        .toList();
    if (offset >= filtered.length) return const [];
    return filtered.sublist(offset, (offset + limit).clamp(0, filtered.length));
  }

  @override
  Future<ScannedDocument?> loadDocument(int id) async => null;

  @override
  Future<void> saveDocument(
    ScannedDocument document, {
    String? category,
  }) async {}
}
