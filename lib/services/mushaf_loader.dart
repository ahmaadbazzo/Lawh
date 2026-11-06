import 'package:flutter/foundation.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:qcf_quran_plus/src/widgets/quran_page/quran_repository.dart';

/// Load the large 604-page dataset only when a Mushaf screen is opened.
class MushafLoader {
  MushafLoader._();

  static Future<void>? _initialization;

  static Future<void> ensureReady(int pageNumber) async {
    _initialization ??= _initialize();
    await _initialization!;
    if (!QcfFontLoader.isFontLoaded(pageNumber)) {
      await QcfFontLoader.ensureFontLoaded(pageNumber);
    }
  }

  static Future<void> _initialize() async {
    await QcfFontLoader.setupFontsAtStartup(
      onProgress: (progress) {
        debugPrint('QCF font loading: ${(progress * 100).toStringAsFixed(1)}%');
      },
    );
    await QuranRepository.instance.ensureLoaded(604);
  }
}
