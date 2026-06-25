import 'package:flutter/foundation.dart';

import '../../domain/models/scanned_document.dart';

class PreviewViewModel extends ChangeNotifier {
  ScannedDocument? _document;
  int _selectedPage = 0;
  int _selectedExport = 0;

  ScannedDocument? get document => _document;
  int get selectedPage => _selectedPage;
  int get selectedExport => _selectedExport;

  ScannedPage? get currentPage {
    final pages = _document?.pages;
    if (pages == null || pages.isEmpty) {
      return null;
    }
    return pages[_selectedPage];
  }

  void showDocument(ScannedDocument document) {
    _document = document;
    _selectedPage = 0;
    notifyListeners();
  }

  void selectPage(int index) {
    final pages = _document?.pages;
    if (pages == null ||
        index < 0 ||
        index >= pages.length ||
        index == _selectedPage) {
      return;
    }

    _selectedPage = index;
    notifyListeners();
  }

  void selectExport(int index) {
    if (_selectedExport == index) {
      return;
    }

    _selectedExport = index;
    notifyListeners();
  }
}
