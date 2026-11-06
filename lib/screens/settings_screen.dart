import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/test_session.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final progress = context.watch<ProgressProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Appearance Section
            _buildSectionHeader('المظهر والعرض'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primaryGreen),
                    title: const Text('الوضع الداكن (Dark Mode)'),
                    subtitle: const Text('ألوان داكنة مريحة للعين أثناء الحفظ الليلي'),
                    value: theme.isDarkMode,
                    activeColor: AppColors.primaryGreenLight,
                    onChanged: (_) => theme.toggleTheme(),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'حجم خط الآيات الكريمة',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${theme.quranFontSize.toInt()} نقطة',
                              style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          min: 20.0,
                          max: 36.0,
                          divisions: 8,
                          value: theme.quranFontSize,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (val) => theme.setQuranFontSize(val),
                        ),
                        // Real-time Preview Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.isDarkMode ? AppColors.surfaceDark : AppColors.bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                          ),
                          child: Text(
                            '﴿ بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ﴾',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'QuranHafs',
                              fontSize: theme.quranFontSize,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Testing Preferences Section
            _buildSectionHeader('خيارات الاختبار والتسميع'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentAmber),
                    title: const Text('مستوى المساعدة الافتراضي'),
                    subtitle: Text(_getHintLabel(theme.hintLevel)),
                    trailing: DropdownButton<HintLevel>(
                      value: theme.hintLevel,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: HintLevel.none,
                          child: Text('بدون مساعدة'),
                        ),
                        DropdownMenuItem(
                          value: HintLevel.firstWord,
                          child: Text('الكلمة الأولى'),
                        ),
                        DropdownMenuItem(
                          value: HintLevel.previousVerse,
                          child: Text('الآية السابقة'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) theme.setHintLevel(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & Reset Section
            _buildSectionHeader('البيانات والتقدم'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restart_alt_rounded, color: AppColors.mistakeRed),
                title: const Text(
                  'تصفير كافة الإحصائيات والتقدم',
                  style: TextStyle(color: AppColors.mistakeRed),
                ),
                subtitle: const Text('إعادة تعيين عدد الآيات، نسبة الدقة وسجل الأخطاء'),
                onTap: () => _confirmReset(context, progress),
              ),
            ),
            const SizedBox(height: 24),

            // About App Section
            _buildSectionHeader('عن تطبيق لَوح'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryGreen, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'تطبيق لَوح (Lawh)',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'الإصدار 1.0.0 • أوفلاين بالكامل',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'تطبيق قرآني متخصص يتيح للحافظ اختبار وتثبيت حفظه عبر الكتابة من الذاكرة بلوحة المفاتيح العادية دون الحاجة للتشكيل، حيث يقوم التطبيق بتطبيع ومقارنة الكلمات وتلوين الصواب والخطأ، وعرض النص بالتشكيل الكامل برواية حفص عن عاصم بالرسم العثماني فور الإجابة الصحيحة.',
                      style: TextStyle(height: 1.6, fontSize: 13.5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'المصدر: نصوص مجمع الملك فهد وموقع تنزيل (Tanzil.net).',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  String _getHintLabel(HintLevel level) {
    switch (level) {
      case HintLevel.none:
        return 'بدون مساعدة (اختبار صرف)';
      case HintLevel.firstWord:
        return 'إظهار الكلمة الأولى من الآية فقط';
      case HintLevel.previousVerse:
        return 'إظهار نص الآية السابقة كمساعد للربط';
    }
  }

  void _confirmReset(BuildContext context, ProgressProvider progress) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد إعادة التعيين'),
          content: const Text('هل ترغب حقاً في تصفير كل سجلات الحفظ والأيام المتتابعة وسجل الأخطاء؟ لا يمكن التراجع عن هذه الخطوة.'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mistakeRed),
              child: const Text('تأكيد التصفير'),
              onPressed: () {
                Navigator.pop(ctx);
                progress.resetAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تصفير كافة الإحصائيات')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
