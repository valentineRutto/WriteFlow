import 'package:flutter/foundation.dart';

enum AppScreen { home, preview, library, settings }

class AppNavigationViewModel extends ChangeNotifier {
  AppScreen _screen = AppScreen.home;

  AppScreen get screen => _screen;

  void show(AppScreen screen) {
    if (_screen == screen) {
      return;
    }

    _screen = screen;
    notifyListeners();
  }
}
