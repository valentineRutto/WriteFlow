import '../models/library_document.dart';

abstract interface class LibraryRepository {
  Future<List<LibraryDocument>> loadDocuments();
}
