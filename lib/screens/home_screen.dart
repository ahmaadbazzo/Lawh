import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/test_session.dart';
import '../providers/progress_provider.dart';
import '../providers/test_provider.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../widgets/ornaments.dart';
import 'mistakes_screen.dart';
import 'settings_screen.dart';
import 'surah_picker_screen.dart';
import 'test_screen.dart';
import 'mushaf_writing_screen.dart';

const String _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لَوح',
          style: TextStyle(
            fontFamily: AppTheme.quranFontFamily,
            fontSize: 30,
            color: AppColors.softGold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppColors.accentGold),
        ),
      ),
      body: MushafBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              _HeroHeader(isDark: isDark),
              const SizedBox(height: 18),
              const _ContinueCard(),
              const SizedBox(height: 12),
              _DailyGoalCard(progress: progress),
              const SizedBox(height: 12),
              const _ContinueWritingCard(),
              const SizedBox(height: 26),
              const OrnateTitle('إحصائيات الحفظ'),
              const SizedBox(height: 12),
              _StatsGrid(progress: progress),
              const SizedBox(height: 26),
              const OrnateTitle('الكتابة على المصحف'),
              const SizedBox(height: 12),
              _ModeTile(
                title: 'الكتابة فوق المصحف',
                subtitle: 'تبقى الآيات كاملة وواضحة أمامك، واكتب مباشرة فوق الصفحة دون اختبار أو تصحيح.',
                icon: Icons.draw_rounded,
                color: AppColors.accentGold,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MushafWritingScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const OrnateTitle('أدوات التسميع'),
              const SizedBox(height: 12),
              _ModeTile(
                title: 'اختبار آية بآية',
                subtitle: 'اكتب الآية غيباً بدون تشكيل ويُطابقها التطبيق كلمة بكلمة.',
                icon: Icons.edit_note_rounded,
                color: AppColors.primaryGreen,
                onTap: () => _openPicker(context, TestMode.verseByVerse),
              ),
              const SizedBox(height: 12),
              _ModeTile(
                title: 'تسميع حر للسورة',
                subtitle: 'اكتب السورة كاملة متتالية ثم اعرف مواضع الخطأ في كل آية.',
                icon: Icons.history_edu_rounded,
                color: const Color(0xFF1E6FA8),
                onTap: () => _openPicker(context, TestMode.freeRecitation),
              ),
              const SizedBox(height: 12),
              _ModeTile(
                title: 'اختبار حسب النطاق',
                subtitle: 'حدد من آية إلى آية داخل السورة لتثبيت مقطع معيّن.',
                icon: Icons.view_week_rounded,
                color: AppColors.accentAmber,
                onTap: () => _openPicker(context, TestMode.range),
              ),
              const SizedBox(height: 26),
              _MistakesBanner(count: progress.mistakes.length),
              const SizedBox(height: 28),
              const StarDivider(),
              const SizedBox(height: 10),
              Text(
                'برواية حفص عن عاصم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  fontSize: 16,
                  color: isDark ? AppColors.softGold : AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openPicker(BuildContext context, TestMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurahPickerScreen(targetMode: mode)),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OrnateFrame(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF0E3A2D), Color(0xFF06241B)]
            : const [AppColors.primaryGreen, AppColors.primaryGreenDark],
      ),
      innerColor: AppColors.softGold.withOpacity(0.55),
      patternColor: AppColors.accentGold.withOpacity(0.14),
      child: Column(
        children: [
          const Text(
            _bismillah,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: 24,
              height: 1.6,
              color: AppColors.softGold,
            ),
          ),
          const SizedBox(height: 10),
          const StarDivider(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentGold, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 68,
                height: 68,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 68,
                  height: 68,
                  child: Icon(Icons.auto_stories_rounded,
                      color: AppColors.accentGold, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'صفحتك القرآنية… اكتب عليها كما تشاء',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: 21,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اقرأ، اكتب، ودوّن على صفحات المصحف بواجهة هادئة وواضحة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever progress changes so the last position stays fresh.
    context.watch<ProgressProvider>();
    final storage = context.read<StorageService>();
    final quran = context.read<QuranService>();

    final lastSurahId = storage.getLastSurahId();
    final lastAyahNum = storage.getLastAyahNum();
    final surah = quran.getSurah(lastSurahId) ?? quran.surahs.firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (surah == null) return;
        final start = lastAyahNum.clamp(1, surah.ayahsCount);
        context.read<TestProvider>().startSurahTest(
              surah: surah,
              mode: TestMode.verseByVerse,
              startAyah: start,
              endAyah: surah.ayahsCount,
            );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TestScreen()),
        );
      },
      child: OrnateFrame(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            const StarIconBadge(icon: Icons.play_arrow_rounded, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متابعة التسميع',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surah != null
                        ? 'سورة ${surah.name} • الآية ${toArabicDigits(lastAyahNum)}'
                        : 'سورة الفاتحة',
                    style: const TextStyle(
                      fontFamily: AppTheme.quranFontFamily,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.accentGold),
          ],
        ),
      ),
    );
  }
}

class _ContinueWritingCard extends StatelessWidget {
  const _ContinueWritingCard();

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final page = storage.getLastWritingPage();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MushafWritingScreen(initialPage: page),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [Color(0xFF174B3A), Color(0xFF0D3025)]
                  : const [Color(0xFFE9D8AD), Color(0xFFF8EED7)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accentGold.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.draw_rounded, color: AppColors.accentGold, size: 26),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'متابعة الكتابة على المصحف',
                      style: TextStyle(
                        fontFamily: AppTheme.quranFontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.softGold : AppColors.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'آخر صفحة عملت عليها: $page من 604',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.progress});

  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _StatTile(
          label: 'الآيات المختبرة',
          value: toArabicDigits(progress.totalTested),
          icon: Icons.checklist_rounded,
          color: AppColors.primaryGreen,
        ),
        _StatTile(
          label: 'نسبة الدقة',
          value: '${toArabicDigits(progress.accuracy.toStringAsFixed(0))}٪',
          icon: Icons.verified_rounded,
          color: const Color(0xFF1E6FA8),
        ),
        _StatTile(
          label: 'التتابع اليومي',
          value: '${toArabicDigits(progress.streak)} يوم',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.accentAmber,
        ),
        _StatTile(
          label: 'السور المتقنة',
          value: toArabicDigits(progress.completedSurahs.length),
          icon: Icons.military_tech_rounded,
          color: AppColors.accentGold,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OrnateFrame(
      radius: 14,
      corners: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          StarIconBadge(icon: icon, size: 38, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: AppTheme.quranFontFamily,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: OrnateFrame(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            StarIconBadge(icon: icon, size: 54, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTheme.quranFontFamily,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.accentGold),
          ],
        ),
      ),
    );
  }
}

class _MistakesBanner extends StatelessWidget {
  const _MistakesBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMistakes = count > 0;
    final accent = hasMistakes ? AppColors.mistakeRed : AppColors.primaryGreen;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MistakesScreen()),
        );
      },
      child: OrnateFrame(
        radius: 16,
        fill: hasMistakes
            ? (isDark ? AppColors.mistakeRedDarkBg : AppColors.mistakeRedBg)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            StarIconBadge(
              icon: hasMistakes ? Icons.error_outline_rounded : Icons.task_alt_rounded,
              size: 50,
              color: accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasMistakes
                        ? 'سجل الأخطاء (${toArabicDigits(count)} آيات للمراجعة)'
                        : 'سجل الأخطاء نظيف',
                    style: TextStyle(
                      fontFamily: AppTheme.quranFontFamily,
                      fontSize: 19,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasMistakes
                        ? 'اضغط لمراجعة الآيات التي أخطأت فيها وإعادة اختبارها.'
                        : 'لا توجد آيات بحاجة لمراجعة حالياً، بارك الله فيك.',
                    style: const TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.accentGold),
          ],
        ),
      ),
    );
  }
}


class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.progress});

  final ProgressProvider progress;

  Future<void> _editGoal(BuildContext context) async {
    final controller = TextEditingController(text: progress.dailyGoal.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الهدف اليومي'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'عدد الآيات في اليوم',
            helperText: 'من ١ إلى ٥٠٠ آية',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 1 && parsed <= 500) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await progress.setDailyGoal(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = progress.dailyCompleted;
    final goal = progress.dailyGoal;
    final ratio = progress.dailyProgress;

    return OrnateFrame(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 6,
                    backgroundColor: AppColors.accentGold.withOpacity(0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                  ),
                ),
                Text(
                  (ratio * 100).round().toString() + '٪',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('هدف اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 3),
                Text(
                  toArabicDigits(done) + ' من ' + toArabicDigits(goal) + ' آية',
                  style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                const SizedBox(height: 5),
                Text(
                  ratio >= 1 ? 'أتممت هدفك اليوم، بارك الله فيك' : 'كل آية تقرّبك من هدفك',
                  style: const TextStyle(fontSize: 12, color: AppColors.accentGold),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل الهدف',
            onPressed: () => _editGoal(context),
            icon: const Icon(Icons.tune_rounded, color: AppColors.accentGold),
          ),
        ],
      ),
    );
  }
}
