// frontend/lib/theme/kirana_colors.dart

import 'package:flutter/material.dart';

class KiranaColors {
  // Premium Modern Fintech Palette
  static const Color primary = Color(0xFF6366F1);      // Vibrant Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFF10B981);    // Emerald Green
  static const Color tertiary = Color(0xFFF59E0B);     // Amber/Gold
  
  // Backgrounds
  static const Color bgLight = Color(0xFFF8FAFC);      // Light Slate Gray
  static const Color bgDark = Color(0xFF0F172A);       // Deep Navy
  
  // Surface / Cards
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);  // Slate
  
  // Accents
  static const Color ink = Color(0xFF1E293B);
  static const Color paper = Color(0xFFF1F5F9);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  
  // Glassmorphic / Translucent
  static Color glassWhite = Colors.white.withOpacity(0.7);
  static Color glassBlack = Colors.black.withOpacity(0.3);

  // Aliases for compatibility
  static const Color darkBrown = ink;
  static const Color warmWhite = paper;
  static const Color saffron = primary;
  static const Color green = success;
  static const Color gold = tertiary;
  static const Color teal = secondary;
  static const Color red = error;
  static const Color redDark = Color(0xFFB91C1C);
  static const Color info = Color(0xFF3B82F6); // Blue

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
    colors: [tertiary, Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient saffronGradient = premiumGradient;

  const KiranaColors._();
}
