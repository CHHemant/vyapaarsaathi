import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'l10n/app_localizations.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/camera/passive_camera_screen.dart';
import 'screens/credit/credit_dossier_screen.dart';
import 'screens/credit/credit_score_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/heatmap_screen.dart';
import 'screens/dispatch/daily_dispatch_screen.dart';
import 'screens/hardware/office_kit_screen.dart';
import 'screens/invoices/create_invoice_screen.dart';
import 'screens/invoices/invoice_list_screen.dart';
import 'screens/invoices/invoice_preview_screen.dart';
import 'screens/khata/party_ledger_screen.dart';
import 'screens/payments/payments_hub_screen.dart';
import 'screens/payments/payment_link_screen.dart';
import 'screens/payments/payment_log_screen.dart';
import 'screens/payments/standee_export_modal.dart';
import 'screens/payments/vpa_qr_screen.dart';
import 'screens/settings/bank_accounts_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/transactions/transaction_history_screen.dart';
import 'screens/voice_ai/voice_assistant_screen.dart';

import 'services/cache_service.dart';
import 'services/local_auth_service.dart';

import 'theme/kirana_colors.dart';

final localeProvider = StateProvider<Locale>(
  (ref) => const Locale('en'),
);

final darkModeProvider = StateProvider<bool>(
  (ref) => false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  await Hive.initFlutter();

  await Future.wait([
    Hive.openBox(HiveBoxes.transactions),
    Hive.openBox(HiveBoxes.creditScore),
    Hive.openBox(HiveBoxes.heatmap),
    Hive.openBox(HiveBoxes.customers),
    Hive.openBox(HiveBoxes.khataEntries),
    Hive.openBox(HiveBoxes.appState),
    Hive.openBox('user_accounts'),
  ]);

  final appState = Hive.box(HiveBoxes.appState);

  final savedLocale = appState.get('selected_locale') as String?;

  final savedDarkMode = appState.get('dark_mode') as bool? ?? false;

  final locale = _parseLocale(savedLocale);

  final authService = LocalAuthService();
  await authService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          (ref) => locale,
        ),
        darkModeProvider.overrideWith(
          (ref) => savedDarkMode,
        ),
      ],
      child: VyapaarSaathiApp(
        authService: authService,
      ),
    ),
  );
}

Locale _parseLocale(String? languageCode) {
  switch (languageCode) {
    case 'mr':
      return const Locale('mr');

    case 'te':
      return const Locale('te');

    case 'en':
    default:
      return const Locale('en');
  }
}

class VyapaarSaathiApp extends ConsumerWidget {
  final LocalAuthService authService;

  const VyapaarSaathiApp({
    super.key,
    required this.authService,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final locale = ref.watch(localeProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp.router(
      title: 'VyapaarSaathi',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
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
        Locale('mr'),
        Locale('te'),
      ],
      routerConfig: _router,
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: KiranaColors.primary,
    primary: KiranaColors.primary,
    secondary: KiranaColors.secondary,
    tertiary: KiranaColors.tertiary,
    surface: isDark ? KiranaColors.surfaceDark : KiranaColors.bg,
    onSurface: isDark ? Colors.white : KiranaColors.onSurface,
    error: KiranaColors.error,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0A0B0E) : KiranaColors.bg,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.bebasNeue(
        fontSize: 48,
        color: isDark ? Colors.white : KiranaColors.primary,
        letterSpacing: 0.8,
      ),
      headlineLarge: GoogleFonts.bebasNeue(
        fontSize: 32,
        color: isDark ? Colors.white : KiranaColors.primary,
        letterSpacing: 0.8,
      ),
      headlineMedium: GoogleFonts.bebasNeue(
        fontSize: 24,
        color: isDark ? Colors.white : KiranaColors.primary,
        letterSpacing: 0.8,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : KiranaColors.onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : KiranaColors.onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : KiranaColors.onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white60 : KiranaColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF0A0B0E) : KiranaColors.bg,
      foregroundColor: isDark ? Colors.white : KiranaColors.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.bebasNeue(
        fontSize: 24,
        color: isDark ? Colors.white : KiranaColors.primary,
        letterSpacing: 1.0,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark
          ? KiranaColors.surfaceDark
          : KiranaColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: KiranaColors.outlineVariant.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: KiranaColors.outlineVariant.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: KiranaColors.primary,
          width: 2,
        ),
      ),
    ),
  );
}

CustomTransitionPage<void> _buildPageTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  const curve = Curves.easeOutCubic;

  final slideTween = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).chain(
    CurveTween(curve: curve),
  );

  final fadeTween = Tween<double>(
    begin: 0,
    end: 1,
  ).chain(
    CurveTween(curve: curve),
  );

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (
      context,
      animation,
      secondaryAnimation,
      child,
    ) {
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
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const DashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/transaction_history',
      name: 'transaction_history',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const TransactionHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/invoice_list',
      name: 'invoice_list',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const InvoiceListScreen(),
      ),
    ),
    GoRoute(
      path: '/create_invoice',
      name: 'create_invoice',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const CreateInvoiceScreen(),
      ),
    ),
    GoRoute(
      path: '/invoice_preview',
      name: 'invoice_preview',
      pageBuilder: (context, state) {
        final invoiceId = state.extra is String ? state.extra as String : null;

        return _buildPageTransition(
          context: context,
          state: state,
          child: InvoicePreviewScreen(
            invoiceId: invoiceId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/party_ledger',
      name: 'party_ledger',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const PartyLedgerScreen(),
      ),
    ),
    GoRoute(
      path: '/payment_log',
      name: 'payment_log',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const PaymentLogScreen(),
      ),
    ),
    GoRoute(
      path: '/payments',
      name: 'payments_hub',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const PaymentsHubScreen(),
      ),
    ),
    GoRoute(
      path: '/payment_link',
      name: 'payment_link',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const PaymentLinkScreen(),
      ),
    ),
    GoRoute(
      path: '/vpa_qr',
      name: 'vpa_qr',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const VpaQrScreen(),
      ),
    ),
    GoRoute(
      path: '/standee',
      name: 'standee',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const StandeeExportModal(),
      ),
    ),
    GoRoute(
      path: '/voice_assistant',
      name: 'voice_assistant',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const VoiceAssistantScreen(),
      ),
    ),
    GoRoute(
      path: '/passive_camera',
      name: 'passive_camera',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const PassiveCameraScreen(),
      ),
    ),
    GoRoute(
      path: '/daily_dispatch',
      name: 'daily_dispatch',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const DailyDispatchScreen(),
      ),
    ),
    GoRoute(
      path: '/office_kit',
      name: 'office_kit',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const OfficeKitScreen(),
      ),
    ),
    GoRoute(
      path: '/credit_score',
      name: 'credit_score',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const CreditScoreScreen(),
      ),
    ),
    GoRoute(
      path: '/credit_dossier',
      name: 'credit_dossier',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const CreditDossierScreen(),
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
      path: '/bank_accounts',
      name: 'bank_accounts',
      pageBuilder: (context, state) => _buildPageTransition(
        context: context,
        state: state,
        child: const BankAccountsScreen(),
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
  ],
  errorPageBuilder: (context, state) => _buildPageTransition(
    context: context,
    state: state,
    child: const DashboardScreen(),
  ),
);

final goRouterProvider = Provider<GoRouter>(
  (ref) => _router,
);
