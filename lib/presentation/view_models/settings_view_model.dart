import 'package:flutter/foundation.dart';

import '../../domain/models/gemma_model_option.dart';
import '../../domain/repositories/gemma_model_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required GemmaModelRepository repository})
    : _repository = repository;

  final GemmaModelRepository _repository;
  List<GemmaModelState> _models = const [];
  bool _isLoading = false;
  String? _busyModelId;
  int _progress = 0;
  String? _errorMessage;

  List<GemmaModelState> get models => _models;
  bool get isLoading => _isLoading;
  String? get busyModelId => _busyModelId;
  int get progress => _progress;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _models = await _repository.loadModels();
    } on Object catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> select(GemmaModelOption model) async {
    if (_busyModelId != null) return;
    _busyModelId = model.id;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.downloadAndActivate(
        model,
        onProgress: (value) {
          _progress = value.clamp(0, 100);
          notifyListeners();
        },
      );
      _models = await _repository.loadModels();
    } on Object catch (error) {
      _errorMessage = error.toString();
    } finally {
      _busyModelId = null;
      notifyListeners();
    }
  }
}
