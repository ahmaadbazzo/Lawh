enum TestMode {
  verseByVerse,   // آية بآية
  freeRecitation, // تسميع حر للسورة كاملة
  range,          // نطاق مخصص أو جزء
}

enum HintLevel {
  none,          // بدون مساعدة
  firstWord,     // الكلمة الأولى
  previousVerse, // الآية السابقة
}

enum WordStatus {
  correct, // كلمة صحيحة (أخضر)
  wrong,   // كلمة خاطئة أو زائدة (أحمر)
  missing, // كلمة ناقصة (أحمر/برتقالي)
}

class WordDiffToken {
  final String text;
  final WordStatus status;

  WordDiffToken({
    required this.text,
    required this.status,
  });

  bool get isCorrect => status == WordStatus.correct;
}

class TestResult {
  final bool isCorrect;
  final double accuracy; // 0.0 to 1.0
  final List<WordDiffToken> userTokens;
  final List<WordDiffToken> targetTokens;
  final String uthmaniVerse;

  TestResult({
    required this.isCorrect,
    required this.accuracy,
    required this.userTokens,
    required this.targetTokens,
    required this.uthmaniVerse,
  });
}
