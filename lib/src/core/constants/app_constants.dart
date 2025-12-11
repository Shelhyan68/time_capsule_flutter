import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color background = Color(0xFF0B0F1A);
  static const Color glassSurface = Colors.white;

  // Couleurs de texte
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF8A8A8A);

  // Couleurs de statut
  static const Color success = Colors.greenAccent;
  static const Color warning = Colors.orangeAccent;
  static const Color error = Colors.redAccent;

  // Couleurs d'état de capsule
  static const Color capsuleLocked = Colors.orangeAccent;
  static const Color capsuleUnlocked = Colors.greenAccent;

  AppColors._();
}

class AppSizes {
  // Padding & Margin
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 28.0;

  // Icon Sizes
  static const double iconSmall = 24.0;
  static const double iconMedium = 32.0;
  static const double iconLarge = 64.0;

  // Max Width
  static const double maxContentWidth = 520.0;

  AppSizes._();
}

class AppStyles {
  // Glassmorphism effect
  static BoxDecoration glassContainer({
    double opacity = 0.08,
    double borderOpacity = 0.12,
    double radius = AppSizes.radiusLarge,
  }) {
    return BoxDecoration(
      color: AppColors.glassSurface.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.glassSurface.withOpacity(borderOpacity),
      ),
    );
  }

  // Text Styles
  static const TextStyle headlineStyle = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyStyle = TextStyle(color: AppColors.textSecondary);

  static const TextStyle captionStyle = TextStyle(
    color: AppColors.textTertiary,
    fontSize: 12,
  );

  AppStyles._();
}
