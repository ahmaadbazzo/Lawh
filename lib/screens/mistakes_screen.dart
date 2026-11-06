import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/progress_provider.dart';
import '../providers/test_provider.dart';
import 'test_screen.dart';

class MistakesScreen extends StatelessWidget {
  const MistakesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final mistakes = progress.mistakes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل مراجعة الأخطاء'),
          actions: [
            if (mistakes.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'مسح كل الأخطاء',
                onPressed: () => _confirmClearAll(context, progress),
              ),
          ],
        ),
        body: mistakes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, size: 72, color: AppColors.correctGreen),
                    SizedBox(height: 16),
                    Text(
                      'سجل الأخطاء نظيف!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'لم تسجل أي أخطاء، أو أنك قمت بمراجعتها جميعاً. أحسنت!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: mistakes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = mistakes[index];
                  return Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header: Surah & Ayah + Delete
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.mistakeRed.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.priority_high_rounded,
                                      color: AppColors.mistakeRed,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'سورة ${item.surahName} - الآية ${item.ayahNum}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.correctGreen),
                                tooltip: 'تم الإتقان (حذف من السجل)',
                                onPressed: () {
                                  progress.removeMistake(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تمت إزالة الآية من سجل الأخطاء')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // What user typed
                          if (item.userInput.isNotEmpty) ...[
                            const Text(
                              'ما كتبته:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.mistakeRedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.userInput,
                                style: const TextStyle(
                                  fontFamily: 'QuranHafs',
                                  fontSize: 16,
                                  color: AppColors.mistakeRed,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Correct verse in Uthmani with diacritics
                          const Text(
                            'النص الصحيح بالتشكيل:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.correctGreenBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '﴿ ${item.targetUthmani} ﴾',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'QuranHafs',
                                fontSize: 18,
                                height: 1.8,
                                color: AppColors.primaryGreenDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Retest Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('إعادة اختبار هذه الآية الآن'),
                            onPressed: () {
                              context.read<TestProvider>().startSingleAyahTest(
                                surahId: item.surahId,
                                ayahNum: item.ayahNum,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TestScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, ProgressProvider progress) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('مسح سجل الأخطاء'),
          content: const Text('هل أنت متأكد من مسح جميع الآيات المسجلة في قائمة الأخطاء؟'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mistakeRed),
              child: const Text('مسح السجل'),
              onPressed: () {
                Navigator.pop(ctx);
                progress.clearAllMistakes();
              },
            ),
          ],
        ),
      ),
    );
  }
}
