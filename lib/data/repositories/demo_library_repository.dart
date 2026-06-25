import '../../domain/models/library_document.dart';
import '../../domain/repositories/library_repository.dart';

class DemoLibraryRepository implements LibraryRepository {
  const DemoLibraryRepository();

  static const _documents = [
    LibraryDocument(
      title: 'Diary - March 1987',
      meta: '3 pages - PDF - Today',
      category: 'Diary',
    ),
    LibraryDocument(
      title: 'Poems - untitled collection',
      meta: '8 pages - EPUB - Yesterday',
      category: 'Poetry',
    ),
    LibraryDocument(
      title: "Grandma's recipe book",
      meta: '14 pages - eBook - Jun 8',
      category: 'Recipe',
    ),
    LibraryDocument(
      title: 'Sunday sermon notes',
      meta: '5 pages - PDF - Jun 2',
      category: 'Sermon',
    ),
    LibraryDocument(
      title: 'Biology - cell division',
      meta: '6 pages - PDF - May 29',
      category: 'Notes',
    ),
    LibraryDocument(
      title: 'Q1 business ledger',
      meta: '11 pages - PDF - May 15',
      category: 'Business',
    ),
  ];

  @override
  Future<List<LibraryDocument>> loadDocuments() async {
    return _documents;
  }
}
