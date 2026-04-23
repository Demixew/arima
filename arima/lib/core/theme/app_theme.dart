import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color brandInk = Color(0xFF17324D);
  static const Color brandOcean = Color(0xFF2F6B8F);
  static const Color brandSand = Color(0xFFF6E7C8);
  static const Color brandMint = Color(0xFFB9E3D1);
  static const Color brandCoral = Color(0xFFE07A5F);
  static const Color canvas = Color(0xFFF8F5EF);
  static const Color panel = Color(0xFFFDFBF7);

  static List<BoxShadow> cardShadow(BuildContext context) => [
    BoxShadow(
      color: brandInk.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData lightTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brandOcean,
      brightness: Brightness.light,
      primary: brandOcean,
      secondary: brandCoral,
      surface: panel,
      error: brandCoral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: brandInk,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: brandInk.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: brandInk.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: brandInk.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandOcean, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOcean,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandOcean,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandOcean,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: brandOcean.withValues(alpha: 0.3)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brandSand.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 40,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: brandInk,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: brandInk,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w600,
          color: brandInk,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: brandInk,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: brandInk,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: brandInk,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: brandInk,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: brandInk,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: brandInk,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: brandInk,
        ),
      ),
    );
  }
}
