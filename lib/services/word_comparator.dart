import 'dart:math';
import '../models/test_session.dart';
import 'text_normalizer.dart';

class WordComparator {
  /// Compares user input against target verse.
  /// Returns a detailed TestResult with word-level highlights.
  static TestResult compare({
    required String userInput,
    required String targetText,
  }) {
    final normUser = TextNormalizer.normalize(userInput);
    final normTarget = TextNormalizer.normalize(targetText);

    final userWords = normUser.isEmpty ? <String>[] : normUser.split(' ');
    final targetWords = normTarget.isEmpty ? <String>[] : normTarget.split(' ');

    if (normUser == normTarget && normTarget.isNotEmpty) {
      return TestResult(
        isCorrect: true,
        accuracy: 1.0,
        userTokens: userWords
            .map((w) => WordDiffToken(text: w, status: WordStatus.correct))
            .toList(),
        targetTokens: targetWords
            .map((w) => WordDiffToken(text: w, status: WordStatus.correct))
            .toList(),
        uthmaniVerse: targetText,
      );
    }

    // Longest Common Subsequence (LCS) Diff
    final m = userWords.length;
    final n = targetWords.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        if (userWords[i] == targetWords[j]) {
          dp[i + 1][j + 1] = dp[i][j] + 1;
        } else {
          dp[i + 1][j + 1] = max(dp[i + 1][j], dp[i][j + 1]);
        }
      }
    }

    // Backtrack alignment
    int i = m;
    int j = n;
    final userTokens = <WordDiffToken>[];
    final targetTokens = <WordDiffToken>[];

    while (i > 0 && j > 0) {
      if (userWords[i - 1] == targetWords[j - 1]) {
        userTokens.add(WordDiffToken(text: userWords[i - 1], status: WordStatus.correct));
        targetTokens.add(WordDiffToken(text: targetWords[j - 1], status: WordStatus.correct));
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        userTokens.add(WordDiffToken(text: userWords[i - 1], status: WordStatus.wrong));
        i--;
      } else {
        targetTokens.add(WordDiffToken(text: targetWords[j - 1], status: WordStatus.missing));
        j--;
      }
    }

    while (i > 0) {
      userTokens.add(WordDiffToken(text: userWords[i - 1], status: WordStatus.wrong));
      i--;
    }
    while (j > 0) {
      targetTokens.add(WordDiffToken(text: targetWords[j - 1], status: WordStatus.missing));
      j--;
    }

    final reversedUser = userTokens.reversed.toList();
    final reversedTarget = targetTokens.reversed.toList();

    final matchedCount = dp[m][n];
    final accuracy = n > 0 ? (matchedCount / n).clamp(0.0, 1.0) : 0.0;
    final isCorrect = (matchedCount == n && m == n);

    return TestResult(
      isCorrect: isCorrect,
      accuracy: accuracy,
      userTokens: reversedUser,
      targetTokens: reversedTarget,
      uthmaniVerse: targetText,
    );
  }
}
