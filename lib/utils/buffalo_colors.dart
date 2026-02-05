import 'package:flutter/material.dart';

class BuffaloColors {
  // Primary Brand Colors - modern restaurant look
  static const Color primary = Color(0xFF172033); // Midnight blue
  static const Color primaryDark = Color(0xFF0F172A); // Deep navy
  static const Color primaryLight = Color(0xFF27364D); // Soft navy

  // Secondary/Accent Colors - vibrant warm CTA
  static const Color secondary = Color(0xFFE85D04); // Tangerine
  static const Color secondaryDark = Color(0xFFCC4F03); // Deep tangerine
  static const Color secondaryLight = Color(0xFFFF7A1A); // Bright orange

  // Tertiary - fresh supporting accent
  static const Color tertiary = Color(0xFF1F9D8B); // Teal
  static const Color tertiaryLight = Color(0xFF2CB8A3); // Light teal

  // Background Colors
  static const Color background = Color(0xFFF7F8FC); // Cool light background
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFEEF2F7); // Soft cool gray

  // Text Colors
  static const Color textPrimary = Color(0xFF141B2D); // Ink
  static const Color textSecondary = Color(0xFF556079); // Slate
  static const Color textLight = Color(0xFF8C96AC); // Muted slate
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  static const Color textOnSecondary = Color(0xFFFFFFFF); // White

  // Status Colors
  static const Color success = Color(0xFF1E9E5A); // Green
  static const Color successLight = Color(0xFF35B96F);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFE11D48); // Rose red
  static const Color errorLight = Color(0xFFF43F5E);
  static const Color info = Color(0xFF2563EB); // Indigo blue
  static const Color infoLight = Color(0xFF3B82F6);

  // Card/Product Colors
  static const Color cardBorder = Color(0xFFDCE3EE);
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
    colors: [primary, Color(0xFF1E2B45)],
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
    0xFF172033,
    <int, Color>{
      50: Color(0xFFECEFF4),
      100: Color(0xFFD5DCE8),
      200: Color(0xFFB8C3D7),
      300: Color(0xFF9AA9C6),
      400: Color(0xFF8395B8),
      500: Color(0xFF172033),
      600: Color(0xFF141C2D),
      700: Color(0xFF111827),
      800: Color(0xFF0E1422),
      900: Color(0xFF0A0E18),
    },
  );
}
