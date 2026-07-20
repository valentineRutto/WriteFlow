import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/library_document.dart';
import '../../domain/models/scanned_document.dart';
import '../../domain/repositories/library_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({required LibraryRepository repository, this.pageSize = 20})
    : assert(pageSize > 0),
      _repository = repository;

  final LibraryRepository _repository;
  final int pageSize;

  final List<LibraryDocument> _documents = [];
  String _query = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _loadGeneration = 0;
  Timer? _searchDebounce;

  List<LibraryDocument> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _isLoadingMore = false;
    _hasMore = true;
    _documents.clear();
    notifyListeners();

    try {
      final page = await _repository.loadDocuments(
        limit: pageSize,
        query: _query,
      );
      if (generation != _loadGeneration) return;
      _documents.addAll(page);
      _hasMore = page.length == pageSize;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final generation = _loadGeneration;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.loadDocuments(
        offset: _documents.length,
        limit: pageSize,
        query: _query,
      );
      if (generation != _loadGeneration) return;
      _documents.addAll(page);
      _hasMore = page.length == pageSize;
    } finally {
      if (generation == _loadGeneration) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void search(String query) {
    if (_query == query) return;
    _query = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), load);
  }

  Future<ScannedDocument?> openDocument(LibraryDocument document) async {
    final id = document.id;
    return id == null ? null : _repository.loadDocument(id);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
