import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors (Navy scheme)
  static const Color primary = Color(0xFF1E3A8A);  // Navy blue
  static const Color primaryDark = Color(0xFF162E6B);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Secondary colors
  static const Color secondary = Color(0xFFFF9800);  // Orange for accents
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFFCC02);

  // Background colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Border and divider colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // Currency specific colors
  static const Color usdColor = Color(0xFF22C55E);  // Green for USD
  static const Color zwlColor = Color(0xFF8B5CF6);  // Purple for ZWL

  // Fuel type colors
  static const Color petrolColor = Color(0xFF059669);
  static const Color dieselColor = Color(0xFF7C3AED);
  static const Color unleadedColor = Color(0xFFDC2626);

  // Payment method colors
  static const Color cardColor = Color(0xFF3B82F6);
  static const Color cashColor = Color(0xFF059669);
  static const Color mobileColor = Color(0xFFEA580C);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );
}
