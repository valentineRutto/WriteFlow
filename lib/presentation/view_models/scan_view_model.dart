import 'package:flutter/foundation.dart';

import '../../domain/models/scanned_document.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/repositories/library_repository.dart';

enum ScanStatus { idle, scanning, completed, failed }

class ScanViewModel extends ChangeNotifier {
  ScanViewModel({
    required ScanRepository repository,
    LibraryRepository? libraryRepository,
  }) : _repository = repository,
       _libraryRepository = libraryRepository;

  final ScanRepository _repository;
  final LibraryRepository? _libraryRepository;

  int _selectedDocumentType = 0;
  bool _batchMode = false;
  ScanStatus _status = ScanStatus.idle;
  String? _errorMessage;

  int get selectedDocumentType => _selectedDocumentType;
  bool get batchMode => _batchMode;
  ScanStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isScanning => _status == ScanStatus.scanning;

  void selectDocumentType(int index) {
    if (_selectedDocumentType == index) {
      return;
    }

    _selectedDocumentType = index;
    notifyListeners();
  }

  void setBatchMode(bool enabled) {
    if (_batchMode == enabled) {
      return;
    }

    _batchMode = enabled;
    notifyListeners();
  }

  Future<ScannedDocument?> scan() async {
    _status = ScanStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      final document = await _repository.scan(
        documentTypeIndex: _selectedDocumentType,
        batchMode: _batchMode,
      );
      await _libraryRepository?.saveDocument(document);
      _status = ScanStatus.completed;
      notifyListeners();
      return document;
    } on Object catch (error) {
      _status = ScanStatus.failed;
      _errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }
}
