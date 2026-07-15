import 'package:flutter/foundation.dart';

import '../../domain/models/scanned_document.dart';
import '../../domain/repositories/text_editing_repository.dart';

class PreviewViewModel extends ChangeNotifier {
  PreviewViewModel({required TextEditingRepository textEditingRepository})
    : _textEditingRepository = textEditingRepository;

  final TextEditingRepository _textEditingRepository;

  ScannedDocument? _document;
  int _selectedPage = 0;
  int _selectedExport = 0;
  bool _isImprovingText = false;
  String? _errorMessage;

  ScannedDocument? get document => _document;
  int get selectedPage => _selectedPage;
  int get selectedExport => _selectedExport;
  bool get isImprovingText => _isImprovingText;
  String? get errorMessage => _errorMessage;

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

  Future<void> improveCurrentPage() async {
    final page = currentPage;
    final document = _document;
    if (page == null || document == null || _isImprovingText) {
      return;
    }

    _isImprovingText = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final improvedText = await _textEditingRepository.improveHandwritingText(
        page.text,
      );
      updateCurrentPageText(
        improvedText,
        aiEngine: 'Gemma on-device text cleanup',
      );
    } on Object catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isImprovingText = false;
      notifyListeners();
    }
  }

  void updateCurrentPageText(String text, {String? aiEngine}) {
    final document = _document;
    if (document == null || _selectedPage >= document.pages.length) {
      return;
    }

    final pages = [...document.pages];
    pages[_selectedPage] = pages[_selectedPage].copyWith(
      text: text,
      aiEngine: aiEngine ?? pages[_selectedPage].aiEngine,
    );
    _document = document.copyWith(pages: pages);
    notifyListeners();
  }
}
