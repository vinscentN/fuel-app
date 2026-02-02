import 'package:flutter/material.dart';

class BuffaloColors {
  // Primary Brand Colors - Professional brewing theme
  static const Color primary = Color(0xFF2C1810); // Dark Brown (rich, professional)
  static const Color primaryDark = Color(0xFF1A0F0A); // Darker Brown
  static const Color primaryLight = Color(0xFF4A2818); // Lighter Brown

  // Secondary/Accent Colors - Amber/Beer tones
  static const Color secondary = Color(0xFFD97706); // Amber/Golden (like beer)
  static const Color secondaryDark = Color(0xFFB45309); // Darker Amber
  static const Color secondaryLight = Color(0xFFF59E0B); // Lighter Amber

  // Tertiary - Complementary professional colors
  static const Color tertiary = Color(0xFF92400E); // Burnt Orange
  static const Color tertiaryLight = Color(0xFFC2410C); // Light Burnt Orange

  // Background Colors
  static const Color background = Color(0xFFF9FAFB); // Very Light Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Light Gray

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Almost Black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textLight = Color(0xFF9CA3AF); // Light Gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  static const Color textOnSecondary = Color(0xFF1F2937); // Dark Gray

  // Status Colors
  static const Color success = Color(0xFF059669); // Green
  static const Color successLight = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFDC2626); // Red
  static const Color errorLight = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB); // Blue
  static const Color infoLight = Color(0xFF3B82F6);

  // Card/Product Colors
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x1A000000);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF2C1810);
  static const Color buttonSecondary = Color(0xFFD97706);
  static const Color buttonDisabled = Color(0xFFD1D5DB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, Color(0xFF3E2723)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  // Opacity variants
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) =>
      secondary.withOpacity(opacity);

  // Material Color Swatch for Theme
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2C1810,
    <int, Color>{
      50: Color(0xFFF5F3F2),
      100: Color(0xFFE6E0DE),
      200: Color(0xFFD5CBC7),
      300: Color(0xFFC4B5B0),
      400: Color(0xFFB7A59E),
      500: Color(0xFF2C1810),
      600: Color(0xFFA38D83),
      700: Color(0xFF99817B),
      800: Color(0xFF8F7673),
      900: Color(0xFF7D6363),
    },
  );
}
