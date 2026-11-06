import 'package:flutter/foundation.dart';
import '../models/mistake_item.dart';
import '../services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  final StorageService _storage;

  int _totalTested = 0;
  int _totalCorrect = 0;
  int _streak = 0;
  List<int> _completedSurahs = [];
  List<MistakeItem> _mistakes = [];

  ProgressProvider(this._storage) {
    loadData();
  }

  int get totalTested => _totalTested;
  int get totalCorrect => _totalCorrect;
  int get streak => _streak;
  int get dailyGoal => _storage.getDailyGoal();
  int get dailyCompleted => _storage.getDailyCompleted();
  double get dailyProgress => (dailyCompleted / dailyGoal).clamp(0.0, 1.0).toDouble();
  List<int> get completedSurahs => _completedSurahs;
  List<MistakeItem> get mistakes => _mistakes;

  double get accuracy =>
      _totalTested > 0 ? (_totalCorrect / _totalTested) * 100 : 100.0;

  void loadData() {
    _totalTested = _storage.getTotalTested();
    _totalCorrect = _storage.getTotalCorrect();
    _streak = _storage.getStreak();
    _completedSurahs = _storage.getCompletedSurahs();
    _mistakes = _storage.getMistakes();
    notifyListeners();
  }

  Future<void> setDailyGoal(int value) async {
    await _storage.setDailyGoal(value);
    notifyListeners();
  }

  Future<void> recordAnswer({required bool isCorrect}) async {
    await _storage.recordAnswer(isCorrect: isCorrect);
    loadData();
  }

  Future<void> markSurahCompleted(int surahId) async {
    await _storage.markSurahCompleted(surahId);
    loadData();
  }

  Future<void> addMistake(MistakeItem mistake) async {
    await _storage.saveMistake(mistake);
    loadData();
  }

  Future<void> removeMistake(String id) async {
    await _storage.removeMistake(id);
    loadData();
  }

  Future<void> clearAllMistakes() async {
    await _storage.clearAllMistakes();
    loadData();
  }

  Future<void> resetAll() async {
    await _storage.resetAllStats();
    loadData();
  }
}
