// frontend/lib/widgets/milestone_badge_widget.dart

import 'package:flutter/material.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';

class MilestoneBadgeWidget extends StatelessWidget {
  final double totalEarnings;
  final int totalTransactions;
  final int streak;

  const MilestoneBadgeWidget({
    required this.totalEarnings,
    required this.totalTransactions,
    required this.streak,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = <_BadgeData>[];

    // Earnings badges
    if (totalEarnings >= 10000) {
      badges.add(_BadgeData(
        emoji: '💰',
        title: 'High Earner',
        description: '₹10,000+ earned!',
        color: KiranaColors.tertiary,
      ));
    }

    // Transaction badges
    if (totalTransactions >= 100) {
      badges.add(_BadgeData(
        emoji: '🏪',
        title: 'Busy Seller',
        description: '100+ sales!',
        color: KiranaColors.primary,
      ));
    }

    // Streak badges
    if (streak >= 7) {
      badges.add(_BadgeData(
        emoji: '🔥',
        title: 'On Fire',
        description: '$streak-day streak!',
        color: KiranaColors.primary,
      ));
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return KiranaCard(
      color: KiranaColors.tertiary.withValues(alpha: 0.05),
      borderColor: KiranaColors.tertiary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: KiranaColors.tertiary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Achievements',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: badges.map((badge) => _BadgeChip(badge: badge)).toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeData {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  _BadgeData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _BadgeChip extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: badge.color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.title,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                badge.description,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
