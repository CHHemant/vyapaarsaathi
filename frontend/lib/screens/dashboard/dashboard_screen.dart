import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../providers/khata/khata_provider.dart';
import '../../providers/transactions/transaction_provider.dart';
import '../../theme/kirana_colors.dart';
import '../../widgets/quick_sale_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTabIndex = 0;

  void _openRoute(String routeName) {
    if (!mounted) return;
    context.pushNamed(routeName);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        setState(() => _currentTabIndex = 0);
        break;
      case 1:
        _openRoute('invoice_list');
        break;
      case 2:
        _openRoute('party_ledger');
        break;
      case 3:
        _openRoute('settings');
        break;
    }
  }

  void _openQuickSale() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return QuickSaleDialog(
          onSaleComplete: () {
            ref.invalidate(transactionProvider);
            ref.invalidate(todayTransactionsProvider);
            ref.invalidate(weeklyTransactionsProvider);
            ref.invalidate(khataEntriesProvider);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodayOverview(),
                      _buildQuickActions(),
                      _buildKhataOverview(),
                      _buildWeeklySales(),
                      _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final date = DateFormat('EEEE, d MMMM').format(now);

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: KiranaColors.bg,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 82,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _displayStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(
                    fontSize: 11,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderIcon(
            Icons.notifications_none_rounded,
            onTap: () {
              _showMessage('Notifications are not configured yet.');
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderIcon(
            Icons.person_outline_rounded,
            onTap: () => _openRoute('settings'),
            filled: true,
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeaderIcon(
    IconData icon, {
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                filled ? KiranaColors.primary : KiranaColors.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: KiranaColors.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: filled ? KiranaColors.onPrimary : KiranaColors.primary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TODAY OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildTodayOverview() {
    final todayAsync = ref.watch(todayTransactionsProvider);

    return todayAsync.when(
      loading: _buildTodayLoading,
      error: (error, stackTrace) => _buildTodayError(),
      data: (transactions) {
        final sales = _sumByCategory(
          transactions,
          TransactionCategory.sales,
        );

        final expenses = _sumByCategory(
          transactions,
          TransactionCategory.expense,
        );

        final net = sales - expenses;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: KiranaColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: KiranaColors.outlineVariant.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: KiranaColors.primary.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "TODAY'S SALES",
                        style: _monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: KiranaColors.onSurfaceVariant,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    _buildSmallStatus(
                      '${transactions.length} TRANSACTIONS',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_formatAmount(sales)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _displayStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.primary,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recorded sales for today',
                  style: _bodyStyle(
                    fontSize: 11,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewMetric(
                        label: 'SALES',
                        value: sales,
                        icon: Icons.trending_up_rounded,
                        color: KiranaColors.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOverviewMetric(
                        label: 'EXPENSES',
                        value: expenses,
                        icon: Icons.trending_down_rounded,
                        color: KiranaColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOverviewMetric(
                        label: 'NET',
                        value: net,
                        icon: Icons.account_balance_wallet_outlined,
                        color: KiranaColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: KiranaColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _openQuickSale,
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: KiranaColors.onPrimary,
                            size: 23,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Sale',
                            style: _bodyStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: KiranaColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewMetric({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 7, 10),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _monoStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '₹${_formatCompactAmount(value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _displayStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: KiranaColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatus(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _monoStyle(
          fontSize: 7,
          fontWeight: FontWeight.w800,
          color: KiranaColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTodayLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildTodayError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: KiranaColors.secondary,
            ),
            const SizedBox(height: 8),
            Text(
              "Unable to load today's sales",
              textAlign: TextAlign.center,
              style: _bodyStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KiranaColors.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(todayTransactionsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUICK ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Quick Actions',
            action: 'All tools',
            onTap: () => _openRoute('settings'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Invoice',
                  subtitle: 'Create invoice',
                  onTap: () => _openRoute('invoice_list'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Khata',
                  subtitle: 'Customer accounts',
                  onTap: () => _openRoute('party_ledger'),
                  secondary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Payments',
                  subtitle: 'QR & payment links',
                  onTap: () => _openRoute('payments_hub'),
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Credit',
                  subtitle: 'Credit tools',
                  onTap: () => _openRoute('credit_score'),
                  tertiary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCompactAction(
                  icon: Icons.mic_none_rounded,
                  label: 'Voice',
                  onTap: () => _openRoute('voice_assistant'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactAction(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () => _openRoute('transaction_history'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactAction(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _openRoute('settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? action,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: _displayStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: KiranaColors.primary,
            ),
          ),
        ),
        if (action != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action,
                      style: _bodyStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KiranaColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: KiranaColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool secondary = false,
    bool tertiary = false,
  }) {
    final iconBackground = secondary
        ? KiranaColors.secondaryContainer
        : tertiary
            ? KiranaColors.tertiaryContainer
            : KiranaColors.primary;

    final iconColor = secondary
        ? KiranaColors.onSecondaryContainer
        : tertiary
            ? KiranaColors.onTertiaryContainer
            : KiranaColors.onPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: KiranaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KiranaColors.outlineVariant.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 21,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: KiranaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _monoStyle(
                        fontSize: 7,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: KiranaColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: KiranaColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: KiranaColors.primary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _monoStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: KiranaColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KHATA
  // ---------------------------------------------------------------------------

  Widget _buildKhataOverview() {
    final receivableAsync = ref.watch(totalReceivableProvider);
    final payableAsync = ref.watch(totalPayableProvider);
    final outstandingAsync = ref.watch(totalOutstandingProvider);

    if (receivableAsync.hasError ||
        payableAsync.hasError ||
        outstandingAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _buildInfoCard(
          icon: Icons.menu_book_rounded,
          title: 'Khata data unavailable',
          message: 'Unable to load your outstanding balances.',
          action: 'Retry',
          onTap: () => ref.invalidate(khataEntriesProvider),
        ),
      );
    }

    if (receivableAsync.isLoading ||
        payableAsync.isLoading ||
        outstandingAsync.isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            color: KiranaColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final receivable = receivableAsync.valueOrNull ?? 0;
    final payable = payableAsync.valueOrNull ?? 0;
    final outstanding = outstandingAsync.valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openRoute('party_ledger'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KiranaColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: KiranaColors.outlineVariant.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'Khata Overview',
                  action: 'View all',
                  onTap: () => _openRoute('party_ledger'),
                ),
                const SizedBox(height: 2),
                Text(
                  'Money you need to track',
                  style: _bodyStyle(
                    fontSize: 11,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _buildKhataBalance(
                        title: 'TO RECEIVE',
                        amount: receivable,
                        icon: Icons.arrow_downward_rounded,
                        color: KiranaColors.tertiary,
                        background: KiranaColors.tertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKhataBalance(
                        title: 'TO PAY',
                        amount: payable,
                        icon: Icons.arrow_upward_rounded,
                        color: KiranaColors.secondary,
                        background: KiranaColors.secondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: KiranaColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 21,
                        color: KiranaColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NET OUTSTANDING',
                              style: _monoStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: KiranaColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_formatAmount(outstanding.abs())}',
                              style: _displayStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: KiranaColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKhataBalance({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: KiranaColors.surfaceContainerLowest.withValues(
                alpha: 0.7,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _monoStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${_formatCompactAmount(amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _displayStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: KiranaColors.secondary,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _bodyStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: _bodyStyle(
                    fontSize: 10,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(action),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEEKLY SALES
  // ---------------------------------------------------------------------------

  Widget _buildWeeklySales() {
    final weeklyAsync = ref.watch(weeklyTransactionsProvider);

    return weeklyAsync.when(
      loading: _buildWeeklyLoading,
      error: (error, stackTrace) => _buildWeeklyError(),
      data: (transactions) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final dailySales = List<double>.generate(7, (index) {
          final day = today.subtract(
            Duration(days: 6 - index),
          );

          return transactions.where((transaction) {
            final timestamp = transaction.timestamp;

            final transactionDay = DateTime(
              timestamp.year,
              timestamp.month,
              timestamp.day,
            );

            return transaction.category == TransactionCategory.sales &&
                transactionDay == day;
          }).fold<double>(
            0,
            (total, transaction) => total + transaction.amount,
          );
        });

        final totalSales = dailySales.fold<double>(
          0,
          (total, amount) => total + amount,
        );

        final maxSales = dailySales.fold<double>(
          0,
          (max, amount) => amount > max ? amount : max,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: KiranaColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: KiranaColors.outlineVariant.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales This Week',
                            style: _displayStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: KiranaColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last 7 days',
                            style: _bodyStyle(
                              fontSize: 10,
                              color: KiranaColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${_formatCompactAmount(totalSales)}',
                          style: _displayStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: KiranaColors.primary,
                          ),
                        ),
                        Text(
                          'TOTAL SALES',
                          style: _monoStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: KiranaColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 135,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      7,
                      (index) {
                        final amount = dailySales[index];

                        final normalizedValue = maxSales > 0
                            ? (amount / maxSales).clamp(0.0, 1.0).toDouble()
                            : 0.0;

                        final day = today.subtract(
                          Duration(days: 6 - index),
                        );

                        final label = index == 6
                            ? 'TODAY'
                            : DateFormat('EEE').format(day).toUpperCase();

                        return _SalesBar(
                          label: label,
                          value: normalizedValue,
                          amount: amount,
                          isHighlight: index == 6,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: KiranaColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildWeeklyError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _buildInfoCard(
        icon: Icons.bar_chart_rounded,
        title: 'Weekly data unavailable',
        message: 'Unable to load your weekly sales.',
        action: 'Retry',
        onTap: () => ref.invalidate(weeklyTransactionsProvider),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECENT ACTIVITY
  // ---------------------------------------------------------------------------

  Widget _buildRecentActivity() {
    final transactionsAsync = ref.watch(transactionProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          _buildSectionHeader(
            title: 'Recent Activity',
            action: 'View all',
            onTap: () => _openRoute('transaction_history'),
          ),
          const SizedBox(height: 10),
          transactionsAsync.when(
            loading: _buildActivityLoading,
            error: (error, stackTrace) => _buildActivityError(),
            data: (transactions) {
              if (transactions.isEmpty) {
                return _buildEmptyActivity();
              }

              final recent = [...transactions]..sort(
                  (a, b) => b.timestamp.compareTo(a.timestamp),
                );

              final visibleTransactions = recent.take(4).toList();

              return Column(
                children:
                    visibleTransactions.map(_buildTransactionItem).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isExpense = transaction.category == TransactionCategory.expense;

    final icon = switch (transaction.category) {
      TransactionCategory.groceries => Icons.shopping_basket_rounded,
      TransactionCategory.vegetables => Icons.eco_rounded,
      TransactionCategory.auto => Icons.local_taxi_rounded,
      TransactionCategory.sales => Icons.arrow_downward_rounded,
      TransactionCategory.expense => Icons.arrow_upward_rounded,
      TransactionCategory.other => Icons.receipt_long_rounded,
    };

    final customerName = transaction.customerName?.trim();

    final title = customerName != null && customerName.isNotEmpty
        ? customerName
        : isExpense
            ? 'Business Expense'
            : 'Direct Sale';

    final categoryLabel = transaction.category.name.toUpperCase();

    final timeLabel =
        TimeOfDay.fromDateTime(transaction.timestamp).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isExpense
                  ? KiranaColors.secondaryContainer
                  : KiranaColors.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isExpense
                  ? KiranaColors.onSecondaryContainer
                  : KiranaColors.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$categoryLabel • $timeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _monoStyle(
                    fontSize: 8,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}₹${_formatAmount(transaction.amount)}',
                style: _displayStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isExpense
                      ? KiranaColors.secondary
                      : KiranaColors.tertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                transaction.isSynced ? 'SYNCED' : 'LOCAL',
                style: _monoStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: KiranaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 34,
            color: KiranaColors.onSurfaceVariant,
          ),
          const SizedBox(height: 9),
          Text(
            'No transactions yet',
            style: _bodyStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: KiranaColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Quick Sale to record your first transaction.',
            textAlign: TextAlign.center,
            style: _bodyStyle(
              fontSize: 10,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: _openQuickSale,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Quick Sale'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildActivityError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: KiranaColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load recent transactions.',
              style: _bodyStyle(
                fontSize: 11,
                color: KiranaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: () {
              ref.invalidate(transactionProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: KiranaColors.surface.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: KiranaColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: KiranaColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Invoices',
              ),
            ),
            SizedBox(
              width: 64,
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: _buildCenterAddButton(),
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 2,
                icon: Icons.menu_book_rounded,
                label: 'Khata',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 3,
                icon: Icons.grid_view_rounded,
                label: 'More',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openQuickSale,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: KiranaColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: KiranaColors.bg,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: KiranaColors.primary.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_rounded,
            size: 28,
            color: KiranaColors.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final active = _currentTabIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleBottomNavigation(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: active
                    ? KiranaColors.primary
                    : KiranaColors.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _monoStyle(
                  fontSize: 8,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? KiranaColors.primary
                      : KiranaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  double _sumByCategory(
    List<Transaction> transactions,
    TransactionCategory category,
  ) {
    return transactions
        .where(
          (transaction) => transaction.category == category,
        )
        .fold<double>(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##,###').format(amount.round());
  }

  String _formatCompactAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }

    return amount.round().toString();
  }

  TextStyle _displayStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w700,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _bodyStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w400,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _monoStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w400,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

// =============================================================================
// WEEKLY SALES BAR
// =============================================================================

class _SalesBar extends StatelessWidget {
  final String label;
  final double value;
  final double amount;
  final bool isHighlight;

  const _SalesBar({
    required this.label,
    required this.value,
    required this.amount,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            amount > 0
                ? '₹${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}K' : amount.round()}'
                : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 7,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
              color: isHighlight
                  ? KiranaColors.secondary
                  : KiranaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 22,
                height: 76 * safeValue,
                decoration: BoxDecoration(
                  color: isHighlight
                      ? KiranaColors.secondaryContainer
                      : KiranaColors.tertiaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? KiranaColors.secondary
                  : KiranaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
