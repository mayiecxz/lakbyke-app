import 'package:flutter/material.dart';

/// Centralized color constants for the entire application.
/// This ensures consistency across all screens and makes rebranding easy.
abstract class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF70D2C8);
  static const Color primaryDark = Color(0xFF4A9B8E);
  static const Color primaryLight = Color(0xFFB5E0D2);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceDim = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x33000000); // 20% black
  static const Color overlayDim = Colors.black54; // For onboarding dimmed background

  // Home Colors
  static const Color homePrimary = Color(0xFF317263); // Dark forest green
  static const Color homeAccent = Color(0xFF75C4B1); // Minty green/teal
  static const Color darkText = Color(0xFF212121);
  static const Color lightText = Colors.white;

  // Onboarding Colors
  static const Color primaryTeal = Color(0xFF70D2C8); // Alias for primary

  // Private constructor to prevent instantiation
  AppColors._();
}
