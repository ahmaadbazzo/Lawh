class TextNormalizer {
  static const Set<String> _daggerAlefExceptions = {
    'الرحمن', 'رحمن', 'ذلك', 'ذلكم', 'ذلكما', 'هذا', 'هذه',
    'هذان', 'هؤلاء', 'اله', 'الاه', 'لكن', 'لكنه', 'اولئك', 'طه', 'يس',
  };

  static String normalize(String text) {
    if (text.isEmpty) return '';
    var result = text.replaceAll(RegExp(r'[\u06D6-\u06ED\u0600-\u0605]'), '');
    result = result.replaceAll('ـ', '').replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    result = result
        .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671\u0672\u0673]'), 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '');
    result = result.replaceAll(RegExp(r'و\u0670'), 'ا');

    final normalizedWords = <String>[];
    for (final word in result.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final stripped = word.replaceAll('\u0670', '');
      normalizedWords.add(
        _daggerAlefExceptions.contains(stripped)
            ? stripped
            : word.replaceAll('\u0670', 'ا'),
      );
    }
    result = normalizedWords.join(' ');
    return result
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u0649\u06CC]'), 'ي')
        .replaceAll(RegExp(r'[.,،؛:!؟?()\[\]{}\-_/\\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String normalizeDigits(String text) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
    final out = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final a = arabicIndic.indexOf(char);
      final e = easternArabicIndic.indexOf(char);
      if (a >= 0) {
        out.write(a);
      } else if (e >= 0) {
        out.write(e);
      } else {
        out.write(char);
      }
    }
    return out.toString();
  }
}
