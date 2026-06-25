import 'package:flutter/foundation.dart';

import '../../domain/models/library_document.dart';
import '../../domain/repositories/library_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({required LibraryRepository repository})
    : _repository = repository;

  final LibraryRepository _repository;

  List<LibraryDocument> _documents = const [];
  String _query = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<LibraryDocument> get documents {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return _documents;
    }

    return _documents
        .where(
          (document) =>
              document.title.toLowerCase().contains(normalizedQuery) ||
              document.category.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _documents = await _repository.loadDocuments();
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (_query == query) {
      return;
    }

    _query = query;
    notifyListeners();
  }
}
