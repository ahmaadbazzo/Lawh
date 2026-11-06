class TextNormalizer {
  static String normalizeForTyping(String text) {
    if (text.isEmpty) return text;
    
    // إزالة علامات الوقف القرآنية (مثل ۖ, ۗ, ۚ) لأن المستخدم لن يكتبها
    String normalized = text.replaceAll(RegExp(r'[\u06D6-\u06DC]'), '');
    
    // توحيد المسافات
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }
}
