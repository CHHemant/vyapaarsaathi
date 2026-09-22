// frontend/lib/theme/kirana_colors.dart

import 'package:flutter/material.dart';

class KiranaColors {
  // Master Dashboard Palette (Based on True Master design)
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Colors.white;

  static const Color secondary = Color(0xFFB22300);
  static const Color secondaryContainer = Color(0xFFDF2E00);
  static const Color onSecondaryContainer = Color(0xFFFFFBFF);

  static const Color tertiary = Color(0xFF658C7B);
  static const Color tertiaryContainer = Color(0xFFC2ECD8);
  static const Color onTertiaryContainer = Color(0xFF002116);

  static const Color bg = Color(0xFFFCF9F2);
  static const Color surface = Color(0xFFFCF9F2);

  // Material 3 Style Surface Containers
  static const Color surfaceContainerLowest = Colors.white;
  static const Color surfaceContainerLow = Color(0xFFF6F3EC);
  static const Color surfaceContainer = Color(0xFFF1EEE7);
  static const Color surfaceContainerHigh = Color(0xFFEBE8E1);
  static const Color surfaceContainerHighest = Color(0xFFE5E2DB);

  static const Color onSurface = Color(0xFF1C1C18);
  static const Color onSurfaceVariant = Color(0xFF444748);

  static const Color outlineVariant = Color(0xFFC4C7C7);
  static const Color error = Color(0xFFBA1A1A);

  // Fixed Color Tokens for Pillars/Badges
  static const Color tertiaryFixed = Color(0xFFC2ECD8);
  static const Color secondaryFixed = Color(0xFFFFDAD2);

  // Legacy/Compatibility Aliases
  static const Color ink = onSurface;
  static const Color paper = bg;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color gold = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6);

  static const Color bgLight = bg;
  static const Color bgDark = Color(0xFF0A0B0E);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1C1E24);

  static const Color darkBrown = onSurface;
  static const Color warmWhite = bg;
  static const Color saffron = secondary;
  static const Color green = Color(0xFF10B981);
  static const Color teal = Color(0xFF658C7B);

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primary, Color(0xFF444444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = premiumGradient;
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  const KiranaColors._();
}
