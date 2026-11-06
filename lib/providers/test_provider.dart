import 'package:flutter/material.dart';
import '../services/text_normalizer.dart';
import '../services/word_comparator.dart';
import '../models/ayah.dart';

class TestProvider extends ChangeNotifier {
  Ayah? _currentAyah;
  String _typedText = "";
  
  List<String> _originalWords = [];
  List<String> _typedWords = [];

  Ayah? get currentAyah => _currentAyah;
  String get typedText => _typedText;
  List<String> get originalWords => _originalWords;
  List<String> get typedWords => _typedWords;

  void setAyah(Ayah ayah) {
    _currentAyah = ayah;
    _originalWords = TextNormalizer.normalizeForTyping(ayah.text).split(' ');
    _typedText = "";
    _typedWords = [];
    notifyListeners();
  }

  void onTextChanged(String text) {
    _typedText = text;
    _typedWords = text.isEmpty ? [] : text.split(' ');
    notifyListeners();
  }

  bool get isAyahCompleted {
    if (_typedWords.length < _originalWords.length) return false;
    for (int i = 0; i < _originalWords.length; i++) {
      if (!WordComparator.isWordCorrect(_originalWords[i], _typedWords[i])) {
        return false;
      }
    }
    return true;
  }
}
