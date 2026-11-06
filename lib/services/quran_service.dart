import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranService {
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  List<Surah> _surahs = [];
  List<Ayah> _ayahs = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Surah> get surahs => _surahs;
  List<Ayah> get ayahs => _ayahs;

  /// Loads Quran and Surahs from bundled asset files
  Future<void> init() async {
    if (_isLoaded) return;

    try {
      final surahsJsonStr = await rootBundle.loadString('assets/data/surahs.json');
      final List<dynamic> surahsList = json.decode(surahsJsonStr);
      _surahs = surahsList.map((j) => Surah.fromJson(j)).toList();

      final quranJsonStr = await rootBundle.loadString('assets/data/quran.json');
      final List<dynamic> ayahsList = json.decode(quranJsonStr);
      _ayahs = ayahsList.map((j) => Ayah.fromJson(j)).toList();

      _isLoaded = true;
    } catch (e) {
      // Fallback if loading fails
      _surahs = [];
      _ayahs = [];
    }
  }

  Surah? getSurah(int id) {
    try {
      return _surahs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Ayah> getAyahsForSurah(int surahId) {
    return _ayahs.where((a) => a.surah == surahId).toList()
      ..sort((a, b) => a.ayah.compareTo(b.ayah));
  }

  Ayah? getAyah(int surahId, int ayahNum) {
    try {
      return _ayahs.firstWhere((a) => a.surah == surahId && a.ayah == ayahNum);
    } catch (_) {
      return null;
    }
  }

  Ayah? getPreviousAyah(int surahId, int currentAyah) {
    if (currentAyah <= 1) return null;
    return getAyah(surahId, currentAyah - 1);
  }

  List<Ayah> getAyahsRange(int surahId, int startAyah, int endAyah) {
    return _ayahs
        .where((a) => a.surah == surahId && a.ayah >= startAyah && a.ayah <= endAyah)
        .toList()
      ..sort((a, b) => a.ayah.compareTo(b.ayah));
  }

  List<Ayah> getAyahsForJuz(int juzNum) {
    return _ayahs.where((a) => a.juz == juzNum).toList()
      ..sort((a, b) {
        if (a.surah != b.surah) return a.surah.compareTo(b.surah);
        return a.ayah.compareTo(b.ayah);
      });
  }

  bool hasAyahsForSurah(int surahId) {
    return _ayahs.any((a) => a.surah == surahId);
  }
}
