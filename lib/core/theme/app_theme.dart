import 'package:flutter/material.dart';

class AppColors {
  // ── App chrome ──
  static const Color appBg      = Color(0xFF1A1A2E);
  static const Color appCard    = Color(0xFF16213E);
  static const Color appSurface = Color(0xFF0F3460);
  static const Color appBorder  = Color(0xFF2A2A4A);

  // ── Primary palette ──
  static const Color primary   = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D4AA);
  static const Color accent    = Color(0xFFFFB300);

  // ── Board ──
  static const Color boardBg        = Color(0xFFF5F0E8);
  static const Color boardBorder    = Color(0xFFCCBB99);
  static const Color boardRoad      = Color(0xFFD4C9B0);
  static const Color boardGrass     = Color(0xFF4CAF50);
  static const Color boardGrassLight = Color(0xFF66BB6A);

  // ── Tile colors ──
  static const Color tileWhite  = Color(0xFFFFFDE7);
  static const Color tileGreen  = Color(0xFFA5D6A7);
  static const Color tileOrange = Color(0xFFFFCC80);
  static const Color tilePurple = Color(0xFFCE93D8);
  static const Color tileBlue   = Color(0xFF90CAF9);
  static const Color tileRed    = Color(0xFFEF9A9A);
  static const Color tileYellow = Color(0xFFFFF176);

  static const Color startTile    = Color(0xFF1A1A2E);
  static const Color surpriseTile = Color(0xFFFF9800);
  static const Color luckyTile    = Color(0xFFFFD700);
  static const Color taxTile      = Color(0xFFE74C3C);
  static const Color bankTile     = Color(0xFF1565C0);
  static const Color parkingTile  = Color(0xFF2E7D32);

  // ── Player token colors ──
  static const List<Color> playerColors = [
    Color(0xFF2196F3),
    Color(0xFFE74C3C),
    Color(0xFF4CAF50),
    Color(0xFFFFD700),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF00BCD4),
  ];

  // ── Status ──
  static const Color success = Color(0xFF2ECC71);
  static const Color danger  = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info    = Color(0xFF3498DB);

  // ── Text ──
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB2BEC3);
  static const Color textHint      = Color(0xFF636E72);
  static const Color textDark      = Color(0xFF1A1A2E);
  static const Color textGold      = Color(0xFFFFB300);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.appCard,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.appBg,
      cardTheme: const CardThemeData(
        color: AppColors.appCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textHint, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.appBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.appSurface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}