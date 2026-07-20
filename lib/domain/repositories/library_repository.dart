import '../models/library_document.dart';
import '../models/scanned_document.dart';

abstract interface class LibraryRepository {
  Future<List<LibraryDocument>> loadDocuments({
    int offset = 0,
    int limit = 20,
    String query = '',
  });

  Future<void> saveDocument(ScannedDocument document, {String? category});

  Future<ScannedDocument?> loadDocument(int id);
}
