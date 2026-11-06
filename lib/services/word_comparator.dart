import 'text_normalizer.dart';

class WordComparator {
  static bool isWordCorrect(String original, String typed) {
    final normOriginal = TextNormalizer.normalizeForTyping(original);
    final normTyped = typed.trim();
    
    return normOriginal == normTyped;
  }

  static bool isPartiallyCorrect(String original, String typed) {
    final normOriginal = TextNormalizer.normalizeForTyping(original);
    final normTyped = typed.trim();
    
    if (normTyped.isEmpty) return false;
    return normOriginal.startsWith(normTyped);
  }
}
