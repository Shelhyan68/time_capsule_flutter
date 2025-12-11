import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Retourne le padding horizontal adapté à la taille d'écran
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 48.0; // Desktop large
    if (width > 800) return 32.0; // Desktop/Tablet
    if (width > 600) return 24.0; // Tablet
    return 16.0; // Mobile
  }

  /// Retourne le padding vertical adapté à la taille d'écran
  static double getVerticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 32.0;
    if (width > 600) return 24.0;
    return 16.0;
  }

  /// Retourne la largeur maximale pour le contenu principal
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 800.0; // Desktop large
    if (width > 800) return 600.0; // Desktop
    if (width > 600) return 500.0; // Tablet
    return width - 32; // Mobile (full width moins padding)
  }

  /// Vérifie si on est sur mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Vérifie si on est sur tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Vérifie si on est sur desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Retourne une taille de texte adaptative
  static double getAdaptiveTextSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return baseSize * 1.2;
    if (width > 800) return baseSize * 1.1;
    if (width < 360) return baseSize * 0.9; // Très petits écrans
    return baseSize;
  }

  /// EdgeInsets adaptatifs pour les pages
  static EdgeInsets getPagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: getVerticalPadding(context),
    );
  }

  /// Retourne le radius des bordures adapté
  static double getBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 28.0;
    if (width > 600) return 24.0;
    return 20.0;
  }

  /// Retourne l'espacement entre éléments
  static double getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 24.0;
    if (width > 600) return 20.0;
    return 16.0;
  }
}

/// Extension pour faciliter l'utilisation
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  double get horizontalPadding => ResponsiveHelper.getHorizontalPadding(this);
  double get verticalPadding => ResponsiveHelper.getVerticalPadding(this);
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
  double get borderRadius => ResponsiveHelper.getBorderRadius(this);
  double get spacing => ResponsiveHelper.getSpacing(this);

  EdgeInsets get pagePadding => ResponsiveHelper.getPagePadding(this);

  double adaptiveTextSize(double baseSize) =>
      ResponsiveHelper.getAdaptiveTextSize(this, baseSize);
}
