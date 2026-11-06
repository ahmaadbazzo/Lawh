import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import 'constants/app_theme.dart';
import 'providers/progress_provider.dart';
import 'providers/test_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/quran_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make framework build errors visible on-device instead of a blank route.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('LAW H FRAMEWORK ERROR: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              'Screen rendering error:\n\n$message\n\nSTACK TRACE:\n${details.stack ?? 'No stack trace available'}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  };

  final storageService = StorageService();
  await storageService.init();

  final quranService = QuranService();
  await quranService.init();

  try {
    await QcfFontLoader.setupFontsAtStartup(
      onProgress: (progress) {
        debugPrint('QCF font loading: ${(progress * 100).toStringAsFixed(1)}%');
      },
    );
  } catch (error, stackTrace) {
    debugPrint('QCF font initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

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
