// frontend/lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../l10n/app_localizations.dart';
import '../models/heatmap_data.dart';
import '../models/transaction.dart';
import '../providers/core_providers.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';
import '../widgets/transaction_tile.dart';
import '../services/voice_service.dart';
import '../widgets/quick_sale_dialog.dart';
import '../widgets/milestone_badge_widget.dart';
import '../widgets/entrance_animation.dart';
import '../main.dart' show darkModeProvider;

// ✅ ALL WIDGET CLASSES MUST BE BEFORE HomeScreen

class _HomeErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _HomeErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: KiranaColors.error),
          const SizedBox(height: 12),
          const Text('Could not load your dashboard'),
          const SizedBox(height: 12),
          RupeeButton(label: 'Retry', showRupeePrefix: false, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _PremiumGreetingHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final VoiceService voiceService;
  final bool isGreetingPlaying;
  final VoidCallback onToggleGreeting;

  const _PremiumGreetingHeader({
    required this.l10n,
    required this.voiceService,
    required this.isGreetingPlaying,
    required this.onToggleGreeting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return KiranaCard(
      color: theme.brightness == Brightness.light ? KiranaColors.primary : KiranaColors.surfaceDark,
      borderColor: Colors.white10,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Vyapari Sahab!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Voice Assistant Ready',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _VoiceWaveform(isPlaying: isGreetingPlaying, onTap: onToggleGreeting),
        ],
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _VoiceWaveform({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: KiranaColors.tertiary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: KiranaColors.tertiary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.stop_rounded : Icons.mic_rounded,
          color: KiranaColors.ink,
          size: 30,
        ),
      ),
    );
  }
}

class _CachedDataBadge extends StatelessWidget {
  final DateTime? cachedAt;

  const _CachedDataBadge({this.cachedAt});

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (cachedAt == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Last updated: ${_relativeTime(cachedAt!)}',
            style: TextStyle(fontSize: 12, color: KiranaColors.darkBrown.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }
}

class _PremiumSummaryCard extends StatelessWidget {
  final DailySummary? summary;
  final int transactionCount;

  const _PremiumSummaryCard({this.summary, required this.transactionCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = summary?.income ?? 0;

    return Row(
      children: [
        Expanded(
          child: KiranaCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: KiranaColors.secondary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Revenue',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${income.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'RobotoMono',
                    color: KiranaColors.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KiranaCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: KiranaColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Orders',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$transactionCount',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'RobotoMono',
                    color: KiranaColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumStreakCard extends StatelessWidget {
  final int streak;
  final bool hasProBadge;

  const _PremiumStreakCard({
    required this.streak,
    required this.hasProBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KiranaCard(
      color: theme.colorScheme.tertiary.withOpacity(0.15),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: theme.colorScheme.tertiary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak! 🔥',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                Text(
                  hasProBadge ? 'Pro Vyapari' : 'Keep it up!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumQuickActions extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onQuickSale;

  const _PremiumQuickActions({
    required this.context,
    required this.onQuickSale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RupeeButton(
                label: 'Quick Sale',
                icon: Icons.add_rounded,
                showRupeePrefix: false,
                onPressed: onQuickSale,
                gradient: KiranaColors.successGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RupeeButton(
                label: 'Udhaar',
                icon: Icons.account_balance_wallet_rounded,
                showRupeePrefix: false,
                onPressed: () => context.pushNamed('udhaar'),
                color: KiranaColors.tertiary,
                gradient: LinearGradient(colors: [KiranaColors.tertiary, Color(0xFFD97706)]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RupeeButton(
          label: 'Create GST Invoice',
          icon: Icons.description_rounded,
          showRupeePrefix: false,
          fullWidth: true,
          onPressed: () => context.pushNamed('invoice'),
          color: KiranaColors.primary,
        ),
      ],
    );
  }
}

class _VoiceCommandChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _VoiceCommandChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontFamily: 'Quicksand',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTransactionsYet extends StatelessWidget {
  const _NoTransactionsYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'No transactions yet today',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Quick Sale" to add one!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySummaryWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime date;

  const _DailySummaryWidget({
    required this.transactions,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const _NoTransactionsYet()
        else
          ...transactions.take(5).map((t) => TransactionTile(transaction: t)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return KiranaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: color ?? KiranaColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: KiranaColors.darkBrown.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ✅ NOW define HomeState and HomeScreen AFTER all widgets

class HomeState {
  final DailySummary? todaySummary;
  final List<Transaction> todayTransactions;
  final int streak;
  final bool hasProVyapariBadge;
  final bool isFromCache;
  final DateTime? cachedAt;

  const HomeState({
    this.todaySummary,
    this.todayTransactions = const [],
    this.streak = 0,
    this.hasProVyapariBadge = false,
    this.isFromCache = false,
    this.cachedAt,
  });
}

class HomeController extends AsyncNotifier<HomeState> {
  Timer? _pollTimer;

  @override
  Future<HomeState> build() async {
    ref.onDispose(() => _pollTimer?.cancel());
    _startPolling();
    return _fetch();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<HomeState> _fetch() async {
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final results = await Future.wait([
        api.getHeatmap(days: 1),
        api.getTransactions(startDate: startOfDay, endDate: now),
      ]);
      final heatmap = results[0] as HeatmapData;
      final transactions = results[1] as List<Transaction>;

      final todaySummary = heatmap.days.isNotEmpty ? heatmap.days.first : null;
      await cache.saveTransactions(transactions);
      final streak = await cache.updateStreakForDay(
        day: startOfDay,
        transactionCountForDay: transactions.length,
      );

      return HomeState(
        todaySummary: todaySummary,
        todayTransactions: transactions,
        streak: streak,
        hasProVyapariBadge: cache.hasProVyapariBadge(),
        isFromCache: false,
      );
    } catch (_) {
      final cachedSummary = cache.getCachedTodaySummary();
      final cachedTransactions = cache.getCachedTransactions();
      return HomeState(
        todaySummary: cachedSummary?.data,
        todayTransactions: cachedTransactions.data
            .where((t) =>
                t.timestamp.year == now.year &&
                t.timestamp.month == now.month &&
                t.timestamp.day == now.day)
            .toList(),
        streak: cache.getStreak(),
        hasProVyapariBadge: cache.hasProVyapariBadge(),
        isFromCache: true,
        cachedAt: cachedSummary?.cachedAt ?? cachedTransactions.cachedAt,
      );
    }
  }
}

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final VoiceService _voiceService;
  late ConfettiController _confettiController;
  bool _isGreetingPlaying = false;

  @override
  void initState() {
    _voiceService = VoiceService(apiService: ref.read(apiServiceProvider));
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    super.initState();
    _initializeVoiceGreeting();
  }

  Future<void> _initializeVoiceGreeting() async {
    await _voiceService.initialize();
    
    final shouldShow = await _voiceService.shouldShowGreetingToday();
    if (shouldShow) {
      setState(() => _isGreetingPlaying = true);
      await _voiceService.playGreeting();
      await _voiceService.markGreetingShownToday();
      setState(() => _isGreetingPlaying = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeAsync = ref.watch(homeControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'VyapaarSaathi',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.pushNamed('settings'),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isDarkMode = ref.watch(darkModeProvider);
              return IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () {
                  ref.read(darkModeProvider.notifier).state = !isDarkMode;
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => context.pushNamed('capture'),
        backgroundColor: KiranaColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.camera_alt_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
              child: homeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _HomeErrorState(
                  onRetry: () => ref.read(homeControllerProvider.notifier).refresh(),
                ),
                data: (state) => _HomeContent(
                  state: state,
                  l10n: l10n,
                  voiceService: _voiceService,
                  isGreetingPlaying: _isGreetingPlaying,
                  onToggleGreeting: _toggleGreeting,
                  onQuickSale: _showQuickSale,
                  confettiController: _confettiController,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: [
                KiranaColors.primary,
                KiranaColors.success,
                KiranaColors.gold,
                Colors.orange,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleGreeting() {
    if (_isGreetingPlaying) {
      _voiceService.stopSpeaking();
      setState(() => _isGreetingPlaying = false);
    } else {
      setState(() => _isGreetingPlaying = true);
      _voiceService.playGreeting().then((_) {
        if (mounted) setState(() => _isGreetingPlaying = false);
      });
    }
  }

  void _showQuickSale() {
    showDialog(
      context: context,
      builder: (context) => QuickSaleDialog(
        onSaleComplete: () {
          if (mounted) {
            final currentIncome = ref.read(homeControllerProvider).value?.todaySummary?.income ?? 0;
            
            if (currentIncome >= 1000) {
              _confettiController.play();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Quick Sale Added! ${currentIncome >= 1000 ? "🎉" : ""}'),
                  ],
                ),
                backgroundColor: KiranaColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            ref.read(homeControllerProvider.notifier).refresh();
          }
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeState state;
  final AppLocalizations l10n;
  final VoiceService voiceService;
  final bool isGreetingPlaying;
  final VoidCallback onToggleGreeting;
  final VoidCallback onQuickSale;
  final ConfettiController confettiController;

  const _HomeContent({
    required this.state,
    required this.l10n,
    required this.voiceService,
    required this.isGreetingPlaying,
    required this.onToggleGreeting,
    required this.onQuickSale,
    required this.confettiController,
  });

  @override
  Widget build(BuildContext context) {
    final summary = state.todaySummary;

    return Stack(
      children: [
        // Subtle Halftone Background
        Positioned.fill(
          child: CustomPaint(
            painter: _HalftonePainter(Theme.of(context).colorScheme.onSurface.withOpacity(0.03)),
          ),
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EntranceAnimation(
              delay: const Duration(milliseconds: 100),
              child: _PremiumGreetingHeader(
                l10n: l10n,
                voiceService: voiceService,
                isGreetingPlaying: isGreetingPlaying,
                onToggleGreeting: onToggleGreeting,
              ),
            ),
            const SizedBox(height: 16),
            if (state.isFromCache) _CachedDataBadge(cachedAt: state.cachedAt),
            EntranceAnimation(
              delay: const Duration(milliseconds: 200),
              child: _PremiumSummaryCard(summary: summary, transactionCount: state.todayTransactions.length),
            ),
            if (state.streak > 0) ...[
              const SizedBox(height: 12),
              EntranceAnimation(
                delay: const Duration(milliseconds: 300),
                child: _PremiumStreakCard(
                  streak: state.streak,
                  hasProBadge: state.hasProVyapariBadge,
                ),
              ),
            ],
            const SizedBox(height: 12),
            EntranceAnimation(
              delay: const Duration(milliseconds: 400),
              child: MilestoneBadgeWidget(
                totalEarnings: state.todaySummary?.income ?? 0,
                totalTransactions: state.todayTransactions.length,
                streak: state.streak,
              ),
            ),
            const SizedBox(height: 16),
            EntranceAnimation(
              delay: const Duration(milliseconds: 500),
              child: _DailySummaryWidget(
                transactions: state.todayTransactions,
                date: DateTime.now(),
              ),
            ),
            const SizedBox(height: 20),
            EntranceAnimation(
              delay: const Duration(milliseconds: 600),
              child: _PremiumQuickActions(
                context: context,
                onQuickSale: onQuickSale,
              ),
            ),
            const SizedBox(height: 24),
            EntranceAnimation(
              delay: const Duration(milliseconds: 700),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: KiranaColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Commands',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: KiranaColors.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            EntranceAnimation(
              delay: const Duration(milliseconds: 800),
              child: KiranaCard(
                color: KiranaColors.primary.withOpacity(0.05),
                child: Column(
                  children: [
                    _VoiceCommandChip(
                      icon: Icons.home,
                      text: '"Home le raa"',
                      onTap: () => _executeVoiceCommand(context, 'home'),
                    ),
                    const SizedBox(height: 8),
                    _VoiceCommandChip(
                      icon: Icons.camera_alt,
                      text: '"Capture"',
                      onTap: () => _executeVoiceCommand(context, 'capture'),
                    ),
                    const SizedBox(height: 8),
                    _VoiceCommandChip(
                      icon: Icons.description,
                      text: '"Bill banao"',
                      onTap: () => _executeVoiceCommand(context, 'bill'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            EntranceAnimation(
              delay: const Duration(milliseconds: 900),
              child: Text(
                'Today',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            if (state.todayTransactions.isEmpty)
              EntranceAnimation(
                delay: const Duration(milliseconds: 1000),
                child: const _NoTransactionsYet(),
              )
            else
              ...List.generate(
                state.todayTransactions.length,
                (index) => EntranceAnimation(
                  delay: Duration(milliseconds: 1000 + (index * 50)),
                  child: TransactionTile(transaction: state.todayTransactions[index]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _executeVoiceCommand(BuildContext context, String command) {
    final router = GoRouter.of(context);
    final parsed = voiceService.parseCommand(command);
    voiceService.execute(parsed, router);
  }
}

class _HalftonePainter extends CustomPainter {
  final Color color;
  _HalftonePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double step = 12.0;

    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}