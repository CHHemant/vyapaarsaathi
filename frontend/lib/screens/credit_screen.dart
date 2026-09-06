// frontend/lib/screens/credit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credit_score.dart';
import '../providers/core_providers.dart';
import '../services/office_kit_service.dart';
import '../theme/kirana_colors.dart';
import '../widgets/credit_score_gauge.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';
import '../widgets/entrance_animation.dart';

class CreditState {
  final CreditScore score;
  final bool isFromCache;
  final DateTime? cachedAt;

  const CreditState({required this.score, this.isFromCache = false, this.cachedAt});
}

class CreditController extends AsyncNotifier<CreditState> {
  @override
  Future<CreditState> build() => _fetch();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<CreditState> _fetch() async {
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(cacheServiceProvider);

    try {
      final score = await api.getCreditScore();
      await cache.saveCreditScore(score);
      return CreditState(score: score);
    } catch (_) {
      final cached = cache.getCachedCreditScore();
      if (cached == null) rethrow;
      return CreditState(score: cached.data, isFromCache: true, cachedAt: cached.cachedAt);
    }
  }
}

final creditControllerProvider = AsyncNotifierProvider<CreditController, CreditState>(CreditController.new);

final _isDownloadingProvider = StateProvider<bool>((ref) => false);

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creditAsync = ref.watch(creditControllerProvider);
    final isDownloading = ref.watch(_isDownloadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Health')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(creditControllerProvider.notifier).refresh(),
        child: creditAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(onRetry: () => ref.read(creditControllerProvider.notifier).refresh()),
          data: (state) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (state.isFromCache) _CachedBadge(cachedAt: state.cachedAt),
              
              EntranceAnimation(
                delay: const Duration(milliseconds: 100),
                child: Center(child: CreditScoreGauge(score: state.score.score)),
              ),
              
              const SizedBox(height: 12),
              
              EntranceAnimation(
                delay: const Duration(milliseconds: 200),
                child: Center(child: _LoanBadge(eligibility: state.score.eligibility)),
              ),
              
              const SizedBox(height: 32),
              
              EntranceAnimation(
                delay: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Expanded(
                      child: _BreakdownCard(
                        icon: Icons.history_rounded,
                        label: 'Consistency',
                        value: '${state.score.breakdown.consistency}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BreakdownCard(
                        icon: Icons.groups_rounded,
                        label: 'Diversity',
                        value: '${state.score.breakdown.diversity}%',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              EntranceAnimation(
                delay: const Duration(milliseconds: 400),
                child: KiranaCard(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: KiranaColors.secondary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average Daily Income', style: theme.textTheme.bodySmall),
                            Text(
                              '₹${state.score.breakdown.avgDailyIncome.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              EntranceAnimation(
                delay: const Duration(milliseconds: 500),
                child: RupeeButton(
                  label: 'Download Financial Report',
                  icon: Icons.file_download_outlined,
                  showRupeePrefix: false,
                  fullWidth: true,
                  isLoading: isDownloading,
                  onPressed: () async {
                    ref.read(_isDownloadingProvider.notifier).state = true;
                    await Future.delayed(const Duration(seconds: 2));
                    ref.read(_isDownloadingProvider.notifier).state = false;
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report generated successfully!'),
                        backgroundColor: KiranaColors.success,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanBadge extends StatelessWidget {
  final LoanEligibility eligibility;
  const _LoanBadge({required this.eligibility});

  Color get _color => switch (eligibility) {
        LoanEligibility.low => KiranaColors.error,
        LoanEligibility.medium => KiranaColors.tertiary,
        LoanEligibility.high => KiranaColors.secondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Text(
        'ELIBILITY: ${eligibility.label.toUpperCase()}',
        style: TextStyle(color: _color, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BreakdownCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KiranaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: KiranaColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CachedBadge extends StatelessWidget {
  final DateTime? cachedAt;
  const _CachedBadge({this.cachedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Showing offline score', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: KiranaColors.error),
          const SizedBox(height: 16),
          const Text('Could not load credit data'),
          const SizedBox(height: 24),
          RupeeButton(label: 'Retry', showRupeePrefix: false, onPressed: onRetry),
        ],
      ),
    );
  }
}
