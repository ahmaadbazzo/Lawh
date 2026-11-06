class TextNormalizer {
  // Common Quranic words where dagger alef is NOT written as standard alef in modern orthography
  static const Set<String> _exceptions = {
    'الرحمن',
    'رحمن',
    'ذلك',
    'ذلكم',
    'ذلكما',
    'هذا',
    'هذه',
    'هذان',
    'هؤلاء',
    'اله',
    'الاه',
    'لكن',
    'لكنه',
    'اولئك',
    'طه',
    'يس',
  };

  /// Normalizes Arabic text (both Quranic verse and user typed input)
  /// for fair and accurate comparison.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    String result = text;

    // 1. Remove Quranic waqf marks, sajdah, rub el hizb and special signs
    // Ranges: \u06D6 - \u06ED, \u06DE, \u06DF, \u0600 - \u0605, \u06DD (ayah end symbol)
    result = result.replaceAll(RegExp(r'[\u06D6-\u06ED\u06DE\u06DF\u0600-\u0605\u06DD]'), '');

    // 2. Unify waw + dagger alef (Uthmani: الصَّلَوٰة -> الصلاة, الزَّكَوٰة -> الزكاة, الحَيَوٰة -> الحياة)
    result = result.replaceAll(RegExp(r'و[\u0670]'), 'ا');

    // 3. Unify all Alef forms (أ, إ, آ, ٱ, ٲ, ٳ, etc.) to bare Alef (ا)
    result = result.replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671\u0672\u0673]'), 'ا');

    // 4. Unify Teh Marbuta (ة) to Heh (ه)
    result = result.replaceAll('\u0629', 'ه');

    // 5. Unify Alef Maqsura (ى) and Persian Yeh to Arabic Yeh (ي)
    result = result.replaceAll(RegExp(r'[\u0649\u06CC]'), 'ي');

    // 6. Remove Tatweel / Kashida (ـ)
    result = result.replaceAll('\u0640', '');

    // 7. Strip standard Tashkeel (harakat: fatha, damma, kasra, sukun, tanween, shadda)
    result = result.replaceAll(RegExp(r'[\u064B-\u065F]'), '');

    // 8. Handle Dagger Alef (\u0670):
    // If the word without dagger alef is in exceptions (e.g. الرحمن, ذلك, هذا), keep it stripped.
    // Otherwise, dagger alef represents an unwritten full alef in modern orthography (e.g. العلمين -> العالمين, الكتب -> الكتاب).
    final words = result.split(RegExp(r'\s+'));
    final normalizedWords = <String>[];

    for (final w in words) {
      if (w.isEmpty) continue;
      final stripped = w.replaceAll('\u0670', '');
      if (_exceptions.contains(stripped)) {
        normalizedWords.add(stripped);
      } else {
        final withAlef = w.replaceAll('\u0670', 'ا');
        normalizedWords.add(withAlef);
      }
    }

    result = normalizedWords.join(' ');

    // 9. Clean any remaining dagger alef or tashkeel marks
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // 10. Normalize punctuation and collapse multi-spaces
    result = result.replaceAll(RegExp(r'[.,،؛:!؟?()\[\]{}\-_\/\\]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}
