import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color brandInk = Color(0xFF1A2238);
  static const Color brandBlue = Color(0xFF5B5FEF);
  static const Color brandSky = Color(0xFF7CC6FF);
  static const Color brandMint = Color(0xFF16C7B7);
  static const Color brandOrange = Color(0xFFFF7A1A);
  static const Color brandSun = Color(0xFFFFC15E);
  static const Color canvas = Color(0xFFF5F7FC);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelSoft = Color(0xFFF0F4FB);

  static List<BoxShadow> cardShadow(BuildContext context) => [
    BoxShadow(
      color: brandInk.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static ThemeData lightTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.light,
      primary: brandBlue,
      secondary: brandMint,
      surface: panel,
      error: brandOrange,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel.withValues(alpha: 0.94),
        indicatorColor: brandBlue.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? brandBlue
                : brandInk.withValues(alpha: 0.7),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brandBlue
                : brandInk.withValues(alpha: 0.6),
          );
        }),
        height: 72,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: brandInk.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: brandInk.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: brandInk.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: brandBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: brandBlue.withValues(alpha: 0.18)),
          backgroundColor: Colors.white.withValues(alpha: 0.72),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelSoft,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 44,
          height: 1.05,
          fontWeight: FontWeight.w800,
          color: brandInk,
        ),
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: brandInk,
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: brandInk,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: brandInk,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: brandInk,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w700,
          color: brandInk,
        ),
      ),
    );
  }
}
