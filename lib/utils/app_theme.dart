import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F0C29);
  static const backgroundLight = Color(0xFF1B1464);
  static const surface = Color(0xFF1a1850);
  static const surfaceLight = Color(0xFF24243E);

  static const primary = Color(0xFFFFD84B);
  static const primaryDark = Color(0xFFFF9500);
  static const primaryGradient = [Color(0xFFFFE066), Color(0xFFFFD84B), Color(0xFFFF9500)];

  static const cellFilled = Color(0xFF4488FF);
  static const cellFilledLight = Color(0xFF5599FF);
  static const cellFilledDark = Color(0xFF3377EE);

  static const satisfied = Color(0xFF00E676);
  static const error = Color(0xFFFF3B30);
  static const hearts = Color(0xFFFF4F7B);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9999CC);
  static const textMuted = Color(0xFF666699);

  static const borderSubtle = Color(0x14FFFFFF); // 8%
  static const borderMedium = Color(0x1FFFFFFF); // 12%
}

class AppGradients {
  static const goldButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: AppColors.primaryGradient,
  );

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.background,
      AppColors.backgroundLight,
      AppColors.surfaceLight,
    ],
  );
}

ThemeData appTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Nunito',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
