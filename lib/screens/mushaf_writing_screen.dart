import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../constants/app_colors.dart';
import '../services/mushaf_loader.dart';

/// A distraction-free writing page. No memorization check or grading.
class MushafWritingScreen extends StatefulWidget {
  const MushafWritingScreen({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  State<MushafWritingScreen> createState() => _MushafWritingScreenState();
}

class _MushafWritingScreenState extends State<MushafWritingScreen> {
  late final PageController _pageController;
  final TextEditingController _writingController = TextEditingController();
  final FocusNode _writingFocus = FocusNode();
  late int _page;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, 604).toInt();
    _pageController = PageController(initialPage: _page - 1);
    _preparePage();
  }

  Future<void> _preparePage() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      await MushafLoader.ensureReady(_page);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (error, stackTrace) {
      debugPrint('LAW H writing page load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _goToPage(int value) {
    final next = value.clamp(1, 604).toInt();
    if (next == _page) return;
    setState(() {
      _page = next;
      _writingController.clear();
    });
    _pageController.jumpToPage(next - 1);
    _preparePage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _writingController.dispose();
    _writingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? const Color(0xFF1D2924) : const Color(0xFFFFFDF7);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الكتابة فوق المصحف'),
          actions: [
            IconButton(
              tooltip: 'مسح الكتابة',
              onPressed: _writingController.clear,
              icon: const Icon(Icons.cleaning_services_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? const Color(0xFF14231D) : const Color(0xFFF1EBDD),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppColors.accentGold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الآيات ظاهرة أمامك دائماً — اكتب مباشرة فوق الصفحة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'صفحة $_page / 604',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: paper,
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.65),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!_loading && !_loadFailed)
                          QuranPageView(
                            pageController: _pageController,
                            isDarkMode: isDark,
                            isTajweed: false,
                            enableTwoPageLayout: false,
                            deferNewPages: false,
                            pageBackgroundColor: paper,
                          ),
                        if (!_loading && !_loadFailed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            child: TextField(
                              controller: _writingController,
                              focusNode: _writingFocus,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.top,
                              keyboardType: TextInputType.multiline,
                              cursorColor: AppColors.accentGold,
                              style: TextStyle(
                                fontFamily: 'QuranHafs',
                                fontSize: 23,
                                height: 2.05,
                                color: isDark
                                    ? const Color(0xFFFFD98A)
                                    : const Color(0xFF14513B),
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'اكتب هنا…',
                                hintStyle: TextStyle(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.22),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        if (_loading)
                          Container(
                            color: paper.withOpacity(0.94),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: AppColors.accentGold),
                                  SizedBox(height: 14),
                                  Text('جارٍ تجهيز صفحات المصحف…'),
                                ],
                              ),
                            ),
                          ),
                        if (_loadFailed)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 42, color: Colors.redAccent),
                                  const SizedBox(height: 10),
                                  const Text('تعذّر تحميل صفحة المصحف'),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _preparePage,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'الصفحة السابقة',
                      onPressed: _page > 1 ? () => _goToPage(_page - 1) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPagePicker(context),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('اختيار الصفحة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'الصفحة التالية',
                      onPressed: _page < 604 ? () => _goToPage(_page + 1) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPagePicker(BuildContext context) async {
    final controller = TextEditingController(text: _page.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'من 1 إلى 604',
            prefixIcon: Icon(Icons.menu_book_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 1 && parsed <= 604) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) _goToPage(value);
  }
}
