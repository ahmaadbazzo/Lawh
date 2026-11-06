import 'package:flutter/material.dart';
import '../models/test_session.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  bool _isDark = false;
  HintLevel _hintLevel = HintLevel.firstWord;
  double _quranFontSize = 26.0;

  ThemeProvider(this._storage) {
    _isDark = _storage.isDarkMode();
    _hintLevel = _storage.getHintLevel();
    _quranFontSize = _storage.getQuranFontSize();
  }

  bool get isDarkMode => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  HintLevel get hintLevel => _hintLevel;
  double get quranFontSize => _quranFontSize;

  void toggleTheme() {
    _isDark = !_isDark;
    _storage.setDarkMode(_isDark);
    notifyListeners();
  }

  void setHintLevel(HintLevel level) {
    _hintLevel = level;
    _storage.setHintLevel(level);
    notifyListeners();
  }

  void setQuranFontSize(double size) {
    _quranFontSize = size;
    _storage.setQuranFontSize(size);
    notifyListeners();
  }
}
