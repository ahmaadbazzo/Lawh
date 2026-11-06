import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:qcf_quran_plus/src/widgets/quran_page/quran_repository.dart';

import 'constants/app_theme.dart';
import 'providers/progress_provider.dart';
import 'providers/test_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/quran_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('LAW H FRAMEWORK ERROR: $details');
    debugPrintStack(stackTrace: details.stack);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              'Screen rendering error:\n\n$details',
              style: const TextStyle(color: Colors.red, fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    LawhBootstrap(
      storageService: StorageService(),
      quranService: QuranService(),
    ),
  );
}

/// Keep the first frame lightweight. The 604-page dataset and fonts are
/// loaded only when the user opens a Mushaf screen.
class LawhBootstrap extends StatefulWidget {
  const LawhBootstrap({
    super.key,
    required this.storageService,
    required this.quranService,
  });

  final StorageService storageService;
  final QuranService quranService;

  @override
  State<LawhBootstrap> createState() => _LawhBootstrapState();
}

class _LawhBootstrapState extends State<LawhBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait<void>([
        widget.storageService.init(),
        widget.quranService.init(),
        Future<void>.delayed(const Duration(milliseconds: 1700)),
      ]);
    } catch (error, stackTrace) {
      debugPrint('LAW H startup initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      child: _ready
          ? MultiProvider(
              key: const ValueKey('lawh-app'),
              providers: [
                Provider<StorageService>.value(value: widget.storageService),
                Provider<QuranService>.value(value: widget.quranService),
                ChangeNotifierProvider<ThemeProvider>(
                  create: (_) => ThemeProvider(widget.storageService),
                ),
                ChangeNotifierProvider<ProgressProvider>(
                  create: (_) => ProgressProvider(widget.storageService),
                ),
                ChangeNotifierProxyProvider<ProgressProvider, TestProvider>(
                  create: (ctx) => TestProvider(
                    widget.quranService,
                    widget.storageService,
                    ctx.read<ProgressProvider>(),
                  ),
                  update: (ctx, progress, previous) =>
                      previous ?? TestProvider(
                        widget.quranService,
                        widget.storageService,
                        progress,
                      ),
                ),
              ],
              child: const LawhApp(),
            )
          : const _AnimatedSplashScreen(key: ValueKey('lawh-splash')),
    );
  }
}

class _AnimatedSplashScreen extends StatefulWidget {
  const _AnimatedSplashScreen({super.key});

  @override
  State<_AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<_AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0D4935), Color(0xFF061F18), Color(0xFF04150F)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(top: -90, right: -75, child: _glow(250)),
              Positioned(bottom: -100, left: -85, child: _glow(280)),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD8B56A).withOpacity(0.7),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD8B56A).withOpacity(0.18),
                                  blurRadius: 34,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 116,
                            height: 116,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF1A6B4D), Color(0xFF0A3828)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              size: 64,
                              color: Color(0xFFE9CC8B),
                            ),
                          ),
                          const Positioned(
                            top: 8,
                            right: 18,
                            child: Icon(Icons.auto_awesome,
                                color: Color(0xFFE9CC8B), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'لَوح',
                        style: TextStyle(
                          fontFamily: 'QuranHafs',
                          fontSize: 46,
                          color: Color(0xFFF3D99D),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مساحتك للقراءة والكتابة على المصحف',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: 92,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.white.withOpacity(0.14),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFD8B56A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFD8B56A).withOpacity(0.12),
            const Color(0xFFD8B56A).withOpacity(0.0),
          ],
        ),
      ),
    );
  }
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
