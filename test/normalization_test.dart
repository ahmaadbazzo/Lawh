import 'package:flutter_test/flutter_test.dart';
import 'package:lawh/services/text_normalizer.dart';
import 'package:lawh/services/word_comparator.dart';
import 'package:lawh/models/test_session.dart';

void main() {
  group('TextNormalizer Unit Tests', () {
    test('Strips standard Tashkeel (harakat)', () {
      const input = 'قُلْ هُوَ اللَّهُ أَحَدٌ';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'قل هو الله احد');
    });

    test('Unifies Alef forms (أ, إ, آ, ٱ -> ا)', () {
      const input = 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'اياك نعبد واياك نستعين');
    });

    test('Unifies Teh Marbuta (ة -> ه)', () {
      const inputWithTeh = 'الصَّلَاة وَالزَّكَاة';
      expect(TextNormalizer.normalize(inputWithTeh), 'الصلاه والزكاه');
    });

    test('Unifies Alef Maqsura (ى -> ي)', () {
      const input = 'هُدًى لِّلْمُتَّقِينَ';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'هدي للمتقين');
    });

    test('Strips Quranic marks and waqf signs (صلى, قلى, مـ, ج, ayah end)', () {
      const input = 'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'ذلك الكتاب لا ريب فيه هدي للمتقين');
    });

    test('Handles Uthmani waw with dagger alef (الصَّلَوٰةَ -> الصلاة)', () {
      const input = 'يُقِيمُونَ ٱلصَّلَوٰةَ وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'يقيمون الصلاه ومما رزقناهم ينفقون');
    });

    test('Smart dagger alef preserves famous words without alef (الرحمن, ذلك, هذا)', () {
      const input = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'بسم الله الرحمن الرحيم');
    });

    test('Folds hamza carriers while preserving their base letters', () {
      expect(TextNormalizer.normalize('سُئِلَ وَسَأَلَ وَرُؤْيَا'), 'سيل وسال ورويا');
    });

    test('Converts Arabic-Indic and Eastern Arabic-Indic digits', () {
      expect(TextNormalizer.normalizeDigits('١١٤'), '114');
      expect(TextNormalizer.normalizeDigits('۱۲۳'), '123');
    });

    test('Removes tatweel / kashida (ـ)', () {
      const input = 'الـــرحـــمـــن';
      final normalized = TextNormalizer.normalize(input);
      expect(normalized, 'الرحمن');
    });
  });

  group('WordComparator Unit Tests', () {
    test('Exact match returns isCorrect = true and accuracy = 1.0', () {
      const user = 'الحمد لله رب العالمين';
      const target = 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ';
      final result = WordComparator.compare(userInput: user, targetText: target);

      expect(result.isCorrect, isTrue);
      expect(result.accuracy, 1.0);
      expect(result.userTokens.every((t) => t.status == WordStatus.correct), isTrue);
    });

    test('User typo detects wrong and missing words', () {
      const user = 'الحمد العالمين'; // Missing 'لله رب'
      const target = 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ';
      final result = WordComparator.compare(userInput: user, targetText: target);

      expect(result.isCorrect, isFalse);
      expect(result.accuracy, lessThan(1.0));
      expect(result.userTokens.first.text, 'الحمد');
      expect(result.userTokens.first.status, WordStatus.correct);
    });
  });
}
