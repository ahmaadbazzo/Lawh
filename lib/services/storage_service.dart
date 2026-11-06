import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mistake_item.dart';
import '../models/test_session.dart';

class StorageService {
  static const String _keyTotalTested = 'lawh_total_tested';
  static const String _keyTotalCorrect = 'lawh_total_correct';
  static const String _keyStreak = 'lawh_streak';
  static const String _keyLastDate = 'lawh_last_date';
  static const String _keyCompletedSurahs = 'lawh_completed_surahs';
  static const String _keyLastSurah = 'lawh_last_surah';
  static const String _keyLastAyah = 'lawh_last_ayah';
  static const String _keyDarkMode = 'lawh_dark_mode';
  static const String _keyHintLevel = 'lawh_hint_level';
  static const String _keyFontSize = 'lawh_font_size';
  static const String _keyMistakes = 'lawh_mistakes_list';
  static const String _keyWritingDraftPrefix = 'lawh_writing_page_';
  static const String _keyLastWritingPage = 'lawh_last_writing_page';
  static const String _keyWritingOpacity = 'lawh_writing_verse_opacity';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Statistics ---
  int getTotalTested() => _prefs.getInt(_keyTotalTested) ?? 0;
  int getTotalCorrect() => _prefs.getInt(_keyTotalCorrect) ?? 0;
  int getStreak() => _prefs.getInt(_keyStreak) ?? 0;
  String getLastDate() => _prefs.getString(_keyLastDate) ?? '';

  Future<void> recordAnswer({required bool isCorrect}) async {
    final tested = getTotalTested() + 1;
    final correct = getTotalCorrect() + (isCorrect ? 1 : 0);
    await _prefs.setInt(_keyTotalTested, tested);
    await _prefs.setInt(_keyTotalCorrect, correct);

    // Update streak based on calendar day
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastDateStr = getLastDate();

    if (lastDateStr.isEmpty) {
      await _prefs.setInt(_keyStreak, 1);
      await _prefs.setString(_keyLastDate, todayStr);
    } else if (lastDateStr != todayStr) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final diffDays = now.difference(lastDate).inDays;
        if (diffDays == 1) {
          await _prefs.setInt(_keyStreak, getStreak() + 1);
        } else if (diffDays > 1) {
          await _prefs.setInt(_keyStreak, 1);
        }
      }
      await _prefs.setString(_keyLastDate, todayStr);
    }
  }

  // --- Progress State ---
  List<int> getCompletedSurahs() {
    final list = _prefs.getStringList(_keyCompletedSurahs) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  Future<void> markSurahCompleted(int surahId) async {
    final list = getCompletedSurahs();
    if (!list.contains(surahId)) {
      list.add(surahId);
      await _prefs.setStringList(
        _keyCompletedSurahs,
        list.map((e) => e.toString()).toList(),
      );
    }
  }

  int getLastSurahId() => _prefs.getInt(_keyLastSurah) ?? 1; // Default to Al-Fatihah
  int getLastAyahNum() => _prefs.getInt(_keyLastAyah) ?? 1;

  Future<void> saveLastPosition(int surahId, int ayahNum) async {
    await _prefs.setInt(_keyLastSurah, surahId);
    await _prefs.setInt(_keyLastAyah, ayahNum);
  }

  // --- Mushaf writing drafts ---
  int getLastWritingPage() => _prefs.getInt(_keyLastWritingPage) ?? 1;

  Future<void> saveLastWritingPage(int page) async {
    await _prefs.setInt(_keyLastWritingPage, page.clamp(1, 604));
  }

  double getWritingOpacity() => _prefs.getDouble(_keyWritingOpacity) ?? 0.30;

  Future<void> saveWritingOpacity(double value) async {
    await _prefs.setDouble(_keyWritingOpacity, value.clamp(0.08, 0.75));
  }

  String getWritingDraft(int page) =>
      _prefs.getString('$_keyWritingDraftPrefix$page') ?? '';

  Future<void> saveWritingDraft(int page, String text) async {
    await _prefs.setString('$_keyWritingDraftPrefix$page', text);
  }

  // --- Settings ---
  bool isDarkMode() => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) async => await _prefs.setBool(_keyDarkMode, value);

  HintLevel getHintLevel() {
    final val = _prefs.getInt(_keyHintLevel) ?? 1; // Default to firstWord
    return HintLevel.values[val.clamp(0, HintLevel.values.length - 1)];
  }

  Future<void> setHintLevel(HintLevel level) async =>
      await _prefs.setInt(_keyHintLevel, level.index);

  double getQuranFontSize() => _prefs.getDouble(_keyFontSize) ?? 26.0;
  Future<void> setQuranFontSize(double size) async =>
      await _prefs.setDouble(_keyFontSize, size);

  // --- Mistakes Management ---
  List<MistakeItem> getMistakes() {
    final jsonStr = _prefs.getString(_keyMistakes);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => MistakeItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMistake(MistakeItem mistake) async {
    final list = getMistakes();
    // Check if mistake already exists for same surah and ayah
    final existingIdx = list.indexWhere(
      (m) => m.surahId == mistake.surahId && m.ayahNum == mistake.ayahNum,
    );
    if (existingIdx != -1) {
      final old = list[existingIdx];
      list[existingIdx] = MistakeItem(
        id: old.id,
        surahId: old.surahId,
        surahName: old.surahName,
        ayahNum: old.ayahNum,
        targetUthmani: mistake.targetUthmani,
        targetNormalized: mistake.targetNormalized,
        userInput: mistake.userInput,
        timestamp: DateTime.now(),
        mistakeCount: old.mistakeCount + 1,
      );
    } else {
      list.insert(0, mistake);
    }
    final jsonStr = json.encode(list.map((m) => m.toJson()).toList());
    await _prefs.setString(_keyMistakes, jsonStr);
  }

  Future<void> removeMistake(String id) async {
    final list = getMistakes()..removeWhere((m) => m.id == id);
    final jsonStr = json.encode(list.map((m) => m.toJson()).toList());
    await _prefs.setString(_keyMistakes, jsonStr);
  }

  Future<void> clearAllMistakes() async {
    await _prefs.remove(_keyMistakes);
  }

  Future<void> resetAllStats() async {
    await _prefs.remove(_keyTotalTested);
    await _prefs.remove(_keyTotalCorrect);
    await _prefs.remove(_keyStreak);
    await _prefs.remove(_keyCompletedSurahs);
    await _prefs.remove(_keyMistakes);
  }
}
