import 'package:flutter/foundation.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:qcf_quran_plus/src/widgets/quran_page/quran_repository.dart';

/// Loads Quran layout metadata once, then loads only the font for the page
/// currently requested by the writing screen. The package's
/// setupFontsAtStartup() eagerly registers all 604 page fonts, which is
/// unnecessary for a surah-at-a-time writing workflow.
class MushafLoader {
  MushafLoader._();

  static Future<void>? _dataInitialization;
  static final Map<int, Future<void>> _fontLoads = <int, Future<void>>{};

  static Future<void> ensureReady(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }

    try {
      _dataInitialization ??= _initializeData();
      await _dataInitialization!;
      if (!QcfFontLoader.isFontLoaded(pageNumber)) {
        final load = _fontLoads.putIfAbsent(
          pageNumber, () => QcfFontLoader.ensureFontLoaded(pageNumber),
        );
        try {
          await load;
        } finally {
          _fontLoads.remove(pageNumber);
        }
      }
    } catch (_) {
      // Do not cache a failed initialization/font request permanently.
      _dataInitialization = null;
      _fontLoads.remove(pageNumber);
      rethrow;
    }
  }

  static Future<void> _initializeData() async {
    // Page metadata is parsed in a background isolate; font files are not
    // eagerly extracted/registered here.
    await QuranRepository.instance.ensureLoaded(604);
    debugPrint('LAW H: Quran page data ready; fonts will load lazily per page.');
  }
}
