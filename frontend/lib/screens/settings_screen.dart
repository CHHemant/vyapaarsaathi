// frontend/lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';
import '../main.dart' show darkModeProvider;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserAsync = ref.watch(currentUserProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () {
              ref.read(darkModeProvider.notifier).state = !isDarkMode;
            },
          ),
        ],
      ),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) => _SettingsContent(user: user, context: context, ref: ref, isDarkMode: isDarkMode),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final dynamic user;
  final BuildContext context;
  final WidgetRef ref;
  final bool isDarkMode;

  const _SettingsContent({
    required this.user,
    required this.context,
    required this.ref,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        KiranaCard(
          color: KiranaColors.primary,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.storeName ?? 'My Store',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user?.phoneNumber ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                onPressed: () => context.pushNamed('profile'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _SettingsSection(
          title: 'Account',
          children: [
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your details',
              onTap: () => context.goNamed('profile'),
            ),
            _SettingsTile(
              icon: Icons.switch_account,
              title: 'Switch Account',
              subtitle: 'Manage multiple accounts',
              onTap: () => context.goNamed('account_switch'),
            ),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of current account',
              onTap: () => _showLogoutDialog(context, ref),
              isDestructive: true,
            ),
          ],
        ),

        const SizedBox(height: 20),

        _SettingsSection(
          title: 'App Settings',
          children: [
            _SettingsTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: isDarkMode ? 'ON' : 'OFF',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(darkModeProvider.notifier).state = value;
                },
              ),
              onTap: () {
                ref.read(darkModeProvider.notifier).state = !isDarkMode;
              },
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () => _showLanguageSelector(context, ref),
            ),
            _SettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage alerts',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications are managed by system settings.')),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        _SettingsSection(
          title: 'About',
          children: [
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About VyapaarSaathi',
              subtitle: 'Version 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'VyapaarSaathi',
                  applicationVersion: '1.0.0',
                  applicationIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KiranaColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.white,
                    ),
                  ),
                  children: [
                    const Text(
                      'Zero-touch financial assistant for informal workers.\n\nBuilt for iQOO Hackathon 2026.',
                    ),
                  ],
                );
              },
            ),
            _SettingsTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'Your data stays on your device',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy: All data is stored locally using Hive.')),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.support,
              title: 'Help & Support',
              subtitle: 'Contact us',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact support at: support@vyapaarsaathi.com')),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 32),

        RupeeButton(
          label: 'Logout',
          icon: Icons.logout_rounded,
          showRupeePrefix: false,
          fullWidth: true,
          color: KiranaColors.error,
          onPressed: () => _showLogoutDialog(context, ref),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout?'),
        content: const Text('You will need to login again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              await authService.logout();
              if (context.mounted) {
                // Since login route was removed in main.dart, we just reload the app or go home
                context.goNamed('home');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: KiranaColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              // ref.read(localeProvider.notifier).state = const Locale('en');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('English', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              // ref.read(localeProvider.notifier).state = const Locale('hi');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('हिंदी (Hindi)', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              // ref.read(localeProvider.notifier).state = const Locale('te');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('తెలుగు (Telugu)', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// Removed _LanguageOption as we use SimpleDialogOption directly now

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return KiranaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: KiranaColors.darkBrown.withOpacity(0.6),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? KiranaColors.error : KiranaColors.darkBrown,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: isDestructive ? KiranaColors.error : KiranaColors.darkBrown,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}