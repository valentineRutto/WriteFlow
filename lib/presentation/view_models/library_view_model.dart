import 'package:flutter/foundation.dart';

import '../../domain/models/library_document.dart';
import '../../domain/repositories/library_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({required LibraryRepository repository, this.pageSize = 5})
    : assert(pageSize > 0),
      _repository = repository;

  final LibraryRepository _repository;
  final int pageSize;

  List<LibraryDocument> _documents = const [];
  String _query = '';
  bool _isLoading = false;
  int _currentPage = 0;

  bool get isLoading => _isLoading;
  int get currentPage => _currentPage + 1;
  int get totalPages =>
      (_filteredDocuments.length / pageSize).ceil().clamp(1, 1 << 31);
  bool get canGoToPreviousPage => _currentPage > 0;
  bool get canGoToNextPage => _currentPage + 1 < totalPages;

  List<LibraryDocument> get documents {
    final filtered = _filteredDocuments;
    final start = _currentPage * pageSize;
    if (start >= filtered.length) return const [];
    return filtered.sublist(
      start,
      (start + pageSize).clamp(0, filtered.length),
    );
  }

  List<LibraryDocument> get _filteredDocuments {
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
    _currentPage = 0;
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (_query == query) {
      return;
    }

    _query = query;
    _currentPage = 0;
    notifyListeners();
  }

  void nextPage() {
    if (!canGoToNextPage) return;
    _currentPage++;
    notifyListeners();
  }

  void previousPage() {
    if (!canGoToPreviousPage) return;
    _currentPage--;
    notifyListeners();
  }
}
