import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0038BC);
  static const Color primaryDark = Color(0xFF002C96);
  static const Color primaryLight = Color(0xFF2A62E3);

  static const Color accent = Color(0xFFEFBF00);
  static const Color accentLight = Color(0xFFFFE48A);

  static const Color white = Color(0xFFFEFEFE);

  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Color(0xFFFEFEFE);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);

  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = accent;
  static const Color danger = Color(0xFFE74C3C);


  // =======================
  // Compatibility (nama lama)
  // =======================

  static const Color green = primary;
  static const Color lightGreen = accent;
  static const Color darkGreen = primary;

  static const Color grey = textSecondary;
  static const Color lightGrey = border;
  static const Color darkGrey = textPrimary;

  static const Color black = textPrimary;
  static const Color transparent = Colors.transparent;

  static const Color card = white;
  static const Color scaffold = background;

  // =======================
// Missing compatibility
// =======================

// Text
static const Color textDark = textPrimary;
static const Color textSoft = textSecondary;

// Primary
static const Color primarySoft = primaryLight;

// Accent
static const Color accentSoft = accentLight;

// Status
static const Color greenSoft = Color(0xFFE8F5E9);

static const Color red = danger;
static const Color orange = warning;

// Navigation
static const Color navIndicator = accent;
static const Color navSelected = primary;
}