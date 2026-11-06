import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'providers/progress_provider.dart';
import 'providers/test_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/quran_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline services
  final storageService = StorageService();
  await storageService.init();

  final quranService = QuranService();
  await quranService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<QuranService>.value(value: quranService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(storageService),
        ),
        ChangeNotifierProxyProvider<ProgressProvider, TestProvider>(
          create: (ctx) => TestProvider(
            quranService,
            storageService,
            ctx.read<ProgressProvider>(),
          ),
          update: (ctx, progress, previous) =>
              previous ?? TestProvider(quranService, storageService, progress),
        ),
      ],
      child: const LawhApp(),
    ),
  );
}

class LawhApp extends StatelessWidget {
  const LawhApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'لَوح',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
