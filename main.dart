import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // मोबाइल के लिए पोर्ट्रेट-फर्स्ट पॉकेट-फ्रेंडली लॉक
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // एज-टू-एज फुल-स्क्रीन डिस्प्ले (ट्रांसपेरेंट स्टेटस बार और नेविगेशन बार)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const LiquidGlassApp());
}

class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({super.key});

  static const Color _accentBlue = Color(0xFF007AFF);
  static const Color _inkDark = Color(0xFF0F172A);
  static const Color _canvasLight = Color(0xFFF7FAFF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Space',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _LiquidScrollBehavior(),
      theme: _buildLightLiquidTheme(),
      builder: (context, child) {
        // बड़े सिस्टम फ़ॉन्ट पर भी UI ओवरफ़्लो से सुरक्षित रखने के लिए स्केल लिमिट
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.90,
          maxScaleFactor: 1.15,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // ऐप खुलते ही पहले LoginScreen दिखेगा; सेशन सक्रिय होने पर सीधे MainShell
      home: appStore.isLoggedIn ? const MainShell() : const LoginScreen(),
    );
  }

  ThemeData _buildLightLiquidTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _accentBlue,
      brightness: Brightness.light,
      primary: _accentBlue,
      surface: _canvasLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: _canvasLight,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: _accentBlue.withValues(alpha: 0.06),
      splashColor: _accentBlue.withValues(alpha: 0.10),

      // Android और iOS दोनों पर स्मूद iOS-स्टाइल साइड-स्वाइप पेज ट्रांज़िशन
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // साफ़ और संतुलित लाइट थीम टेक्स्ट व कर्सर स्टाइल
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _accentBlue,
        selectionColor: _accentBlue.withValues(alpha: 0.22),
        selectionHandleColor: _accentBlue,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _inkDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _inkDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// पूरे ऐप में स्मूद बाउंसिंग (iOS जैसा) स्क्रॉल अनुभव
class _LiquidScrollBehavior extends MaterialScrollBehavior {
  const _LiquidScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
