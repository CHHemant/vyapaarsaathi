// frontend/lib/screens/account_switch_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';

class AccountSwitchScreen extends ConsumerWidget {
  const AccountSwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authService = ref.read(authServiceProvider);
    final accountsAsync = authService.getAllAccounts();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Switch Account'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: accountsAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final accounts = snapshot.data ?? [];
          return _AccountList(accounts: accounts, context: context, ref: ref);
        },
      ),
    );
  }
}

class _AccountList extends StatelessWidget {
  final List<dynamic> accounts;
  final BuildContext context;
  final WidgetRef ref;

  const _AccountList({
    required this.accounts,
    required this.context,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Current Account
        if (accounts.isNotEmpty) ...[
          Text(
            'CURRENT ACCOUNT',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          _AccountTile(
            account: accounts.first,
            isCurrent: true,
            onTap: () {
              // Already current account
            },
          ),
          const SizedBox(height: 32),
        ],

        // Other Accounts
        if (accounts.length > 1) ...[
          Text(
            'OTHER ACCOUNTS',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          ...accounts.skip(1).map((account) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AccountTile(
                  account: account,
                  isCurrent: false,
                  onTap: () => _switchAccount(account.id),
                ),
              )),
          const SizedBox(height: 32),
        ],

        // Add New Account Button
        RupeeButton(
          label: 'Add New Account',
          icon: Icons.add_circle_outline_rounded,
          showRupeePrefix: false,
          fullWidth: true,
          color: KiranaColors.secondary,
          onPressed: () => context.goNamed('home'), // No login route available
        ),

        const SizedBox(height: 24),

        // Info Card
        KiranaCard(
          color: KiranaColors.primary.withOpacity(0.05),
          borderColor: KiranaColors.primary.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: KiranaColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Each account has separate offline data. Switch anytime to manage another store.',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _switchAccount(String accountId) async {
    final authService = ref.read(authServiceProvider);
    await authService.switchAccount(accountId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account switched successfully!'),
          backgroundColor: KiranaColors.success,
        ),
      );
      context.goNamed('home');
    }
  }
}

class _AccountTile extends StatelessWidget {
  final dynamic account;
  final bool isCurrent;
  final VoidCallback onTap;

  const _AccountTile({
    required this.account,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KiranaCard(
      elevation: isCurrent ? 8 : 2,
      borderColor: isCurrent ? KiranaColors.primary : Colors.transparent,
      borderWidth: isCurrent ? 2 : 1,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent ? KiranaColors.primary : KiranaColors.ink.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.store_rounded,
              color: isCurrent ? Colors.white : KiranaColors.ink,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.storeName,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  account.phoneNumber,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.check_circle_rounded, color: KiranaColors.secondary)
          else
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }
}
