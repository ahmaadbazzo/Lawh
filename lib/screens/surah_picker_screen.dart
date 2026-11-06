import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../widgets/ornaments.dart';
import '../models/surah.dart';
import '../models/test_session.dart';
import '../providers/test_provider.dart';
import '../services/quran_service.dart';
import '../services/text_normalizer.dart';
import 'test_screen.dart';

class SurahPickerScreen extends StatefulWidget {
  final TestMode targetMode;

  const SurahPickerScreen({
    Key? key,
    this.targetMode = TestMode.verseByVerse,
  }) : super(key: key);

  @override
  State<SurahPickerScreen> createState() => _SurahPickerScreenState();
}

class _SurahPickerScreenState extends State<SurahPickerScreen> {
  final QuranService _quranService = QuranService();
  String _searchQuery = '';
  String _activeFilter = 'الكل'; // الكل, جزء عم, مكية, مدنية

  @override
  Widget build(BuildContext context) {
    final allSurahs = _quranService.surahs;

    final filtered = allSurahs.where((s) {
      // Filter by category
      if (_activeFilter == 'جزء عم' && s.startJuz != 30) return false;
      if (_activeFilter == 'مكية' && !s.isMeccan) return false;
      if (_activeFilter == 'مدنية' && s.isMeccan) return false;

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final query = TextNormalizer.normalize(_searchQuery);
        final normalizedName = TextNormalizer.normalize(s.name);
        final normalizedDigits = TextNormalizer.normalizeDigits(_searchQuery.trim());
        final matchesName = query.isNotEmpty && normalizedName.contains(query);
        final matchesEnglish = s.englishName.toLowerCase().contains(_searchQuery.trim().toLowerCase());
        final matchesNumber = s.id.toString() == normalizedDigits;
        return matchesName || matchesEnglish || matchesNumber;
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.targetMode == TestMode.verseByVerse
                ? 'اختر سورة للاختبار'
                : widget.targetMode == TestMode.freeRecitation
                    ? 'اختر سورة للتسميع الحر'
                    : 'اختبار حسب النطاق',
          ),
        ),
        body: MushafBackground(child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('الكل'),
                  const SizedBox(width: 8),
                  _buildFilterChip('جزء عم'),
                  const SizedBox(width: 8),
                  _buildFilterChip('مكية'),
                  const SizedBox(width: 8),
                  _buildFilterChip('مدنية'),
                ],
              ),
            ),

            const Divider(height: 1),

            // Surah List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.search_off_rounded, size: 54, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'لم يتم العثور على سور مطابقة',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final surah = filtered[index];
                        final hasData = _quranService.hasAyahsForSurah(surah.id);

                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: AyahMarker(number: surah.id, size: 48),
                            title: Row(
                              children: [
                                Text(
                                  'سورة ${surah.name}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.quranFontFamily,
                                    fontSize: 21,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: surah.isMeccan
                                        ? Colors.orange.withOpacity(0.15)
                                        : Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    surah.revelationType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: surah.isMeccan ? Colors.deepOrange : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${toArabicDigits(surah.ayahsCount)} آيات • الجزء ${toArabicDigits(surah.startJuz)} • ${surah.englishName}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!hasData)
                                  Tooltip(
                                    message: 'بيانات هذه السورة تُحمّل عبر السكربت أو نص التنزيل',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('أوفلاين', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                              ],
                            ),
                            onTap: () => _handleSurahTap(context, surah),
                          ),
                        );
                      },
                    ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryGreen : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _activeFilter = label),
    );
  }

  void _handleSurahTap(BuildContext context, Surah surah) {
    if (widget.targetMode == TestMode.range) {
      _showRangeDialog(context, surah);
    } else {
      context.read<TestProvider>().startSurahTest(
        surah: surah,
        mode: widget.targetMode,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestScreen()),
      );
    }
  }

  void _showRangeDialog(BuildContext context, Surah surah) {
    int start = 1;
    int end = surah.ayahsCount.clamp(1, 10);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تحديد نطاق الاختبار: سورة ${surah.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إجمالي عدد آيات السورة: ${surah.ayahsCount} آية',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('من الآية:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: start,
                                items: List.generate(
                                  surah.ayahsCount,
                                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() {
                                      start = val;
                                      if (end < start) end = start;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('إلى الآية:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: end,
                                items: List.generate(
                                  surah.ayahsCount - start + 1,
                                  (i) => DropdownMenuItem(
                                    value: start + i,
                                    child: Text('${start + i}'),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => end = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      child: Text('بدء الاختبار من $start إلى $end'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<TestProvider>().startSurahTest(
                          surah: surah,
                          mode: TestMode.range,
                          startAyah: start,
                          endAyah: end,
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
        );
      },
    );
  }
}
