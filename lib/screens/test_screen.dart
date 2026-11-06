import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../widgets/ornaments.dart';
import '../models/test_session.dart';
import '../providers/test_provider.dart';
import '../providers/theme_provider.dart';
import '../services/text_normalizer.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _GhostTextController _textController = _GhostTextController();
  String? _activeAyahText;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final test = context.watch<TestProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentAyah = test.currentAyah;
    final surah = test.currentSurah;
    if (currentAyah != null && _activeAyahText != currentAyah.text) {
      _activeAyahText = currentAyah.text;
      _textController.targetText = currentAyah.text;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeAyahText == currentAyah.text) {
          _textController.clear();
        }
      });
    }

    // Handle completed session
    if (test.isSessionFinished) {
      return _buildFinishedView(context, test, isDark);
    }

    if (currentAyah == null || surah == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('الاختبار')),
          body: const Center(
            child: Text('لا توجد آيات متوفرة للاختبار في هذه السورة حالياً.'),
          ),
        ),
      );
    }

    final progressRatio = test.sessionAyahs.isNotEmpty
        ? (test.currentIndex + 1) / test.sessionAyahs.length
        : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سورة ${surah.name}'),
          actions: [
            // Hint Level Popup Menu
            PopupMenuButton<HintLevel>(
              icon: const Icon(Icons.lightbulb_outline_rounded),
              tooltip: 'مستوى المساعدة',
              initialValue: test.hintLevel,
              onSelected: (level) => test.setHintLevel(level),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: HintLevel.none,
                  child: Text('بدون مساعدة'),
                ),
                const PopupMenuItem(
                  value: HintLevel.firstWord,
                  child: Text('إظهار الكلمة الأولى'),
                ),
                const PopupMenuItem(
                  value: HintLevel.previousVerse,
                  child: Text('إظهار الآية السابقة'),
                ),
              ],
            ),
          ],
        ),
        body: MushafBackground(child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.borderLight,
              color: AppColors.accentGold,
              minHeight: 6,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Surah cartouche (like a Mushaf surah header)
                    SurahBanner(
                      title: 'سورة ${surah.name}',
                      subtitle:
                          'الآية ${toArabicDigits(currentAyah.ayah)} من ${toArabicDigits(surah.ayahsCount)}  •  ${toArabicDigits((progressRatio * 100).toInt())}٪',
                    ),
                    const SizedBox(height: 16),

                    // Hint Area
                    if (test.hintText.isNotEmpty) _buildHintCard(context, test.hintText, isDark),
                    const SizedBox(height: 16),

                    // Mode 1 & 3: Verse by Verse input
                    if (test.mode != TestMode.freeRecitation) ...[
                      // Input TextField
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: test.isChecked
                                ? (test.lastResult?.isCorrect == true
                                    ? AppColors.correctGreen
                                    : AppColors.mistakeRed)
                                : AppColors.accentGold.withOpacity(0.7),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          autofocus: true,
                          enabled: !test.isChecked,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'QuranHafs',
                            fontSize: theme.quranFontSize - 4,
                            height: 1.6,
                            color: isDark ? AppColors.softGold : AppColors.primaryGreenDark,
                          ),
                          maxLines: 4,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'اكتب الآية فوق النص الظاهر...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (val) => test.setUserInput(val),
                          onSubmitted: (_) {
                            if (!test.isChecked && test.userInput.trim().isNotEmpty) {
                              test.checkCurrentVerse();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verification Result Area
                      if (test.isChecked && test.lastResult != null)
                        _buildResultFeedback(context, test.lastResult!, currentAyah.text, currentAyah.ayah, theme.quranFontSize, isDark),

                      const SizedBox(height: 20),

                      // Action Buttons
                      _buildActionButtons(context, test),
                    ] else ...[
                      // Mode 2: Free Continuous Recitation
                      _buildFreeRecitationInput(context, test, theme.quranFontSize, isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildHintCard(BuildContext context, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softGold.withOpacity(isDark ? 0.15 : 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.accentAmber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'QuranHafs',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreenDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultFeedback(
    BuildContext context,
    TestResult result,
    String uthmaniVerse,
    int ayahNumber,
    double quranFontSize,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: result.isCorrect
            ? (isDark ? AppColors.correctGreenDarkBg : AppColors.correctGreenBg)
            : (isDark ? AppColors.mistakeRedDarkBg : AppColors.mistakeRedBg),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isCorrect ? AppColors.correctGreen : AppColors.mistakeRed,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Status
          Row(
            children: [
              Icon(
                result.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: result.isCorrect ? AppColors.correctGreen : AppColors.mistakeRed,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isCorrect
                      ? 'ما شاء الله! إجابة صحيحة ومتقنة 🌟'
                      : 'تنبيه: هناك كلمات بحاجة لتصحيح',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: result.isCorrect ? AppColors.correctGreen : AppColors.mistakeRed,
                  ),
                ),
              ),
              Text(
                'الدقة: ${(result.accuracy * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Word-by-word diff if not completely correct
          if (!result.isCorrect) ...[
            const Text(
              'مقارنة الكلمات المكتوبة:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.userTokens.map((token) {
                final isOk = token.status == WordStatus.correct;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOk
                        ? AppColors.correctGreen.withOpacity(0.2)
                        : AppColors.mistakeRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOk ? AppColors.correctGreen : AppColors.mistakeRed,
                    ),
                  ),
                  child: Text(
                    token.text,
                    style: TextStyle(
                      fontFamily: 'QuranHafs',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOk ? AppColors.correctGreen : AppColors.mistakeRed,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // Display the FULL verse in Hafs 'an 'Asim with full diacritics
          const Text(
            'نص الآية برواية حفص عن عاصم (بالتشكيل الكامل):',
            style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          OrnateFrame(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$uthmaniVerse '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: AyahMarker(
                        number: ayahNumber,
                        size: quranFontSize * 1.25,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  fontSize: quranFontSize,
                  height: 2.0,
                  color: isDark ? AppColors.softGold : AppColors.primaryGreenDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TestProvider test) {
    if (!test.isChecked) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تحقق من الحفظ'),
              onPressed: test.userInput.trim().isEmpty
                  ? null
                  : () {
                      test.checkCurrentVerse();
                    },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              child: const Text('تخطي'),
              onPressed: () {
                test.checkCurrentVerse(allowEmpty: true);
              },
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          if (test.lastResult?.isCorrect != true) ...[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                onPressed: () {
                  _textController.clear();
                  test.retryCurrentVerse();
                  FocusScope.of(context).requestFocus(_focusNode);
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded), // RTL Next
              label: Text(
                test.currentIndex + 1 < test.sessionAyahs.length
                    ? 'الآية التالية'
                    : 'إنهاء الاختبار',
              ),
              onPressed: () {
                _textController.clear();
                test.nextVerse();
                if (!test.isSessionFinished) {
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFreeRecitationInput(
    BuildContext context,
    TestProvider test,
    double quranFontSize,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'التسميع الحر: اكتب آيات السورة بالتتابع (افصل بين الآيات بسطر جديد)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 12,
          style: TextStyle(
            fontFamily: 'QuranHafs',
            fontSize: quranFontSize - 6,
            height: 1.8,
          ),
          decoration: InputDecoration(
            hintText: 'اكتب السورة كاملة هنا من ذاكرتك بدون تشكيل...',
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
          onChanged: (val) => test.setFreeRecitationText(val),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('فحص ومطابقة السورة كاملة'),
          onPressed: test.freeRecitationText.trim().isEmpty
              ? null
              : () => test.checkFreeRecitation(),
        ),
      ],
    );
  }

  Widget _buildFinishedView(BuildContext context, TestProvider test, bool isDark) {
    final results = test.freeRecitationResults;
    final isFree = test.mode == TestMode.freeRecitation && results.isNotEmpty;
    final correct = results.where((r) => r.isCorrect).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اكتمل الاختبار')),
        body: MushafBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                SurahBanner(title: 'سورة ${test.currentSurah?.name ?? ""}'),
                const SizedBox(height: 22),
                const Center(
                  child: StarIconBadge(
                    icon: Icons.military_tech_rounded,
                    size: 110,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isFree
                      ? 'أصبت ${toArabicDigits(correct)} من ${toArabicDigits(results.length)} آية'
                      : 'مبارك! أتممت التسميع',
                  style: const TextStyle(
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isFree && correct < results.length
                      ? 'راجع الآيات المعلّمة بالأحمر، وقد أُضيفت إلى سجل الأخطاء.'
                      : 'بارك الله في حفظك وزادك نوراً.',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (isFree) ...[
                  const SizedBox(height: 22),
                  const OrnateTitle('نتيجة كل آية'),
                  const SizedBox(height: 12),
                  for (var i = 0; i < results.length; i++)
                    _buildFreeResultTile(test, i, results[i], isDark),
                ],
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('العودة للرئيسية'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeResultTile(
    TestProvider test,
    int index,
    TestResult result,
    bool isDark,
  ) {
    final ayah = test.sessionAyahs[index];
    final ok = result.isCorrect;
    final color = ok ? AppColors.correctGreen : AppColors.mistakeRed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OrnateFrame(
        radius: 14,
        corners: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AyahMarker(number: ayah.ayah, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ok
                            ? 'صحيحة'
                            : 'الدقة ${toArabicDigits((result.accuracy * 100).toInt())}٪',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (!ok) ...[
                    const SizedBox(height: 6),
                    Text(
                      ayah.text,
                      style: TextStyle(
                        fontFamily: AppTheme.quranFontFamily,
                        fontSize: 19,
                        height: 1.9,
                        color: isDark ? AppColors.softGold : AppColors.primaryGreenDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Displays the user's input and the remaining verse guide in one text layout,
/// so wrapping and cursor positioning stay aligned.
class _GhostTextController extends TextEditingController {
  String targetText = '';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final typed = text;
    final targetDisplayWords = targetText.trim().isEmpty
        ? <String>[]
        : targetText.trim().split(RegExp(r'\s+'));
    final targetWords = targetDisplayWords
        .map(TextNormalizer.normalize)
        .toList();
    final typedWords = typed.trim().isEmpty
        ? <String>[]
        : typed.trimRight().split(RegExp(r'\s+'));
    final spans = <InlineSpan>[];

    for (var i = 0; i < typedWords.length; i++) {
      final word = typedWords[i];
      final normalized = TextNormalizer.normalize(word);
      final isLastPartial = i == typedWords.length - 1 && !typed.endsWith(' ');
      final isCorrect = i < targetWords.length &&
          (normalized == targetWords[i] ||
           (isLastPartial && targetWords[i].startsWith(normalized) && normalized.isNotEmpty));
      spans.add(TextSpan(
        text: word,
        style: base.copyWith(
          color: isCorrect
              ? base.color
              : const Color(0xFFE05252),
        ),
      ));
      if (i < typedWords.length - 1 || typed.endsWith(' ')) {
        spans.add(TextSpan(text: ' ', style: base));
      }
    }

    final completedCount = typedWords.length;
    final remaining = completedCount < targetWords.length
        ? targetDisplayWords.sublist(completedCount).join(' ')
        : '';
    if (remaining.isNotEmpty) {
      if (typedWords.isNotEmpty && !typed.endsWith(' ')) {
        spans.add(TextSpan(text: ' ', style: base.copyWith(color: base.color?.withOpacity(0.28))));
      }
      spans.add(TextSpan(
        text: remaining,
        style: base.copyWith(color: base.color?.withOpacity(0.28)),
      ));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: targetText, style: base.copyWith(color: base.color?.withOpacity(0.28))));
    }
    return TextSpan(style: base, children: spans);
  }
}
