import 'package:flutter/material.dart';
import '../models/ayah.dart';
import '../models/surah.dart';
import '../models/test_session.dart';
import '../models/mistake_item.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../services/word_comparator.dart';
import 'progress_provider.dart';

class TestProvider extends ChangeNotifier {
  final QuranService _quranService;
  final StorageService _storageService;
  final ProgressProvider _progressProvider;

  TestMode _mode = TestMode.verseByVerse;
  HintLevel _hintLevel = HintLevel.firstWord;

  Surah? _currentSurah;
  List<Ayah> _sessionAyahs = [];
  int _currentIndex = 0;

  // Active inputs & results
  String _userInput = '';
  TestResult? _lastResult;
  bool _isChecked = false;
  bool _isSessionFinished = false;

  // Continuous free recitation
  String _freeRecitationText = '';
  List<TestResult> _freeRecitationResults = [];

  TestProvider(this._quranService, this._storageService, this._progressProvider);

  TestMode get mode => _mode;
  HintLevel get hintLevel => _hintLevel;
  Surah? get currentSurah => _currentSurah;
  List<Ayah> get sessionAyahs => _sessionAyahs;
  int get currentIndex => _currentIndex;
  String get userInput => _userInput;
  TestResult? get lastResult => _lastResult;
  bool get isChecked => _isChecked;
  bool get isSessionFinished => _isSessionFinished;
  String get freeRecitationText => _freeRecitationText;
  List<TestResult> get freeRecitationResults => _freeRecitationResults;

  Ayah? get currentAyah =>
      _sessionAyahs.isNotEmpty && _currentIndex < _sessionAyahs.length
          ? _sessionAyahs[_currentIndex]
          : null;

  Ayah? get previousAyah {
    if (_currentSurah == null || currentAyah == null) return null;
    return _quranService.getPreviousAyah(_currentSurah!.id, currentAyah!.ayah);
  }

  String get hintText {
    if (currentAyah == null) return '';
    switch (_hintLevel) {
      case HintLevel.none:
        return '';
      case HintLevel.firstWord:
        return 'بداية الآية: "${currentAyah!.firstWord}..."';
      case HintLevel.previousVerse:
        final prev = previousAyah;
        if (prev != null) {
          return 'الآية السابقة: "${prev.text}"';
        }
        return 'بداية السورة (الآية الأولى)';
    }
  }

  void setHintLevel(HintLevel level) {
    _hintLevel = level;
    notifyListeners();
  }

  void setUserInput(String text) {
    _userInput = text;
    notifyListeners();
  }

  void setFreeRecitationText(String text) {
    _freeRecitationText = text;
    notifyListeners();
  }

  /// Initialize test session for a specific Surah
  void startSurahTest({
    required Surah surah,
    TestMode mode = TestMode.verseByVerse,
    int? startAyah,
    int? endAyah,
    HintLevel? hint,
  }) {
    _mode = mode;
    _currentSurah = surah;
    _currentIndex = 0;
    _userInput = '';
    _lastResult = null;
    _isChecked = false;
    _isSessionFinished = false;
    _freeRecitationText = '';
    _freeRecitationResults = [];
    if (hint != null) _hintLevel = hint;

    if (startAyah != null && endAyah != null) {
      _sessionAyahs = _quranService.getAyahsRange(surah.id, startAyah, endAyah);
    } else {
      _sessionAyahs = _quranService.getAyahsForSurah(surah.id);
    }

    _storageService.saveLastPosition(surah.id, currentAyah?.ayah ?? 1);
    notifyListeners();
  }

  /// Initialize test for a specific single Ayah (e.g. from mistakes review)
  void startSingleAyahTest({required int surahId, required int ayahNum}) {
    final surah = _quranService.getSurah(surahId);
    final ayah = _quranService.getAyah(surahId, ayahNum);
    if (surah == null || ayah == null) return;

    _mode = TestMode.verseByVerse;
    _currentSurah = surah;
    _sessionAyahs = [ayah];
    _currentIndex = 0;
    _userInput = '';
    _lastResult = null;
    _isChecked = false;
    _isSessionFinished = false;
    notifyListeners();
  }

  /// Check the verse typed by the user in Verse-by-Verse mode
  void checkCurrentVerse({bool allowEmpty = false}) {
    if (currentAyah == null) return;
    if (!allowEmpty && _userInput.trim().isEmpty) return;

    final result = WordComparator.compare(
      userInput: _userInput,
      targetText: currentAyah!.text,
    );

    _lastResult = result;
    _isChecked = true;

    // Record stats
    _progressProvider.recordAnswer(isCorrect: result.isCorrect);

    if (!result.isCorrect) {
      // Record mistake
      final mistake = MistakeItem(
        id: '${currentAyah!.surah}_${currentAyah!.ayah}_${DateTime.now().millisecondsSinceEpoch}',
        surahId: _currentSurah!.id,
        surahName: _currentSurah!.name,
        ayahNum: currentAyah!.ayah,
        targetUthmani: currentAyah!.text,
        targetNormalized: currentAyah!.normalized,
        userInput: _userInput,
        timestamp: DateTime.now(),
      );
      _progressProvider.addMistake(mistake);
    }

    notifyListeners();
  }

  /// Advance to next verse
  void nextVerse() {
    if (_currentIndex + 1 < _sessionAyahs.length) {
      _currentIndex++;
      _userInput = '';
      _lastResult = null;
      _isChecked = false;
      _storageService.saveLastPosition(_currentSurah!.id, currentAyah!.ayah);
    } else {
      _isSessionFinished = true;
      if (_currentSurah != null) {
        _progressProvider.markSurahCompleted(_currentSurah!.id);
      }
    }
    notifyListeners();
  }

  /// Retry current verse
  void retryCurrentVerse() {
    _userInput = '';
    _lastResult = null;
    _isChecked = false;
    notifyListeners();
  }

  /// Check free recitation mode
  void checkFreeRecitation() {
    if (_currentSurah == null || _freeRecitationText.trim().isEmpty) return;

    _freeRecitationResults = [];
    final allAyahs = _sessionAyahs;

    // Split user text into verses (by newline or period or approximate)
    final lines = _freeRecitationText
        .split(RegExp(r'[\n\r]+'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    int correctCount = 0;
    for (int i = 0; i < allAyahs.length; i++) {
      final userLine = i < lines.length ? lines[i] : '';
      final res = WordComparator.compare(
        userInput: userLine,
        targetText: allAyahs[i].text,
      );
      if (res.isCorrect) correctCount++;
      _freeRecitationResults.add(res);

      _progressProvider.recordAnswer(isCorrect: res.isCorrect);
      if (!res.isCorrect && userLine.isNotEmpty) {
        _progressProvider.addMistake(
          MistakeItem(
            id: '${allAyahs[i].surah}_${allAyahs[i].ayah}_free',
            surahId: _currentSurah!.id,
            surahName: _currentSurah!.name,
            ayahNum: allAyahs[i].ayah,
            targetUthmani: allAyahs[i].text,
            targetNormalized: allAyahs[i].normalized,
            userInput: userLine,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    _isChecked = true;
    _isSessionFinished = true;
    if (correctCount == allAyahs.length) {
      _progressProvider.markSurahCompleted(_currentSurah!.id);
    }
    notifyListeners();
  }
}
