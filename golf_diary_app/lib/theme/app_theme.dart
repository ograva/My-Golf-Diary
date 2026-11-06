import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF1B5E20);
  static const amber = Color(0xFFFFC107);
}

ThemeData buildGolfTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  const seed = AppColors.green;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: AppColors.green,
      secondary: AppColors.amber,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.green,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.amber.withOpacity(0.35),
      checkmarkColor: AppColors.green,
      labelStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
