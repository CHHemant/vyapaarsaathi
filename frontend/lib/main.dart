// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/credit_screen.dart';
import 'screens/udhaar_screen.dart';
import 'screens/invoice_screen.dart';
import 'screens/heatmap_screen.dart';
// import 'screens/login_screen.dart'; // ✅ Commented out
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/account_switch_screen.dart';
import 'services/cache_service.dart' show HiveBoxes;
import 'services/local_auth_service.dart';
import 'theme/kirana_colors.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
final darkModeProvider = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(HiveBoxes.transactions),
    Hive.openBox(HiveBoxes.creditScore),
    Hive.openBox(HiveBoxes.heatmap),
    Hive.openBox(HiveBoxes.customers),
    Hive.openBox(HiveBoxes.appState),
    Hive.openBox('user_accounts'),
  ]);

  final authService = LocalAuthService();
  await authService.initialize();

  runApp(
    ProviderScope(
      child: VyapaarSaathiApp(authService: authService),
    ),
  );
}

class VyapaarSaathiApp extends ConsumerWidget {
  final LocalAuthService authService;

  const VyapaarSaathiApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp.router(
      title: 'VyapaarSaathi',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('te'),
      ],
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: KiranaColors.primary,
      primary: KiranaColors.primary,
      secondary: KiranaColors.secondary,
      tertiary: KiranaColors.tertiary,
      surface: KiranaColors.bgLight,
      onSurface: KiranaColors.ink,
      error: KiranaColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KiranaColors.bgLight,
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.tenorSans(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: KiranaColors.ink,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.tenorSans(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: KiranaColors.ink,
        ),
        titleLarge: GoogleFonts.tenorSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: KiranaColors.ink,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: KiranaColors.ink,
        ),
        bodyLarge: GoogleFonts.quicksand(
          color: KiranaColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.quicksand(
          color: KiranaColors.ink.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KiranaColors.bgLight,
        foregroundColor: KiranaColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.tenorSans(
          fontSize: 24,
          color: KiranaColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: KiranaColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: KiranaColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: KiranaColors.ink, fontWeight: FontWeight.w600),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: KiranaColors.primary,
      brightness: Brightness.dark,
      primary: KiranaColors.primary,
      secondary: KiranaColors.secondary,
      tertiary: KiranaColors.tertiary,
      surface: KiranaColors.surfaceDark,
      onSurface: Colors.white,
      error: KiranaColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KiranaColors.bgDark,
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.tenorSans(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.tenorSans(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.tenorSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.quicksand(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.quicksand(
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KiranaColors.bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.tenorSans(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: KiranaColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KiranaColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: KiranaColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

CustomTransitionPage<void> _buildPageTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.05, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/capture',
      name: 'capture',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const CaptureScreen(),
      ),
    ),
    GoRoute(
      path: '/credit-score',
      name: 'creditScore',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const CreditScreen(),
      ),
    ),
    GoRoute(
      path: '/invoice',
      name: 'invoice',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const InvoiceScreen(),
      ),
    ),
    GoRoute(
      path: '/udhaar',
      name: 'udhaar',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const UdhaarScreen(),
      ),
    ),
    GoRoute(
      path: '/heatmap',
      name: 'heatmap',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const HeatmapScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/account-switch',
      name: 'account_switch',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const AccountSwitchScreen(),
      ),
    ),
  ],
  errorPageBuilder: (context, state) => _buildPageTransition(
    context: context,
    state: state,
    child: const HomeScreen(),
  ),
);

final goRouterProvider = Provider<GoRouter>((ref) => _router);