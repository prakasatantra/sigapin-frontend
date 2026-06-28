import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Golden/Amber)
  static const Color primary = Color(0xFFFBC02D); // Amber 700
  static const Color primaryLight = Color(0xFFFFF176); // Yellow 300
  static const Color primaryDark = Color(0xFFF9A825); // Amber 800

  // Secondary Palette (Orange)
  static const Color secondary = Color(0xFFFB8C00); // Orange 600
  static const Color secondaryLight = Color(0xFFFFB74D); // Orange 300
  static const Color secondaryDark = Color(0xFFEF6C00); // Orange 800

  // Neutral Palette
  static const Color background = Color(0xFFFFFDE7); // Yellow 50 (Very light pastel)
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  
  // Text Colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF424242);
  static const Color onBackground = Color(0xFF424242);
  static const Color textSecondary = Color(0xFF757575);

  // Dark Mode Palette
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE1E1E1);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFBC02D), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFB8C00), Color(0xFFFBC02D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
