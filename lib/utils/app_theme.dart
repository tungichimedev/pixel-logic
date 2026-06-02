import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0F0C29);
  static const backgroundLight = Color(0xFF1B1464);
  static const surface = Color(0xFF1F1D5C);
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

  static const borderSubtle = Color(0x22FFFFFF); // 13%
  static const borderMedium = Color(0x33FFFFFF); // 20%
}

class AppFonts {
  static TextStyle pixel({
    double fontSize = 12,
    Color color = AppColors.primary,
    double letterSpacing = 1,
  }) {
    return GoogleFonts.pressStart2p(
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
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

/// Wraps a child in the app's gradient background with a blue radial glow.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 0.8,
            colors: [
              const Color(0xFF4466FF).withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
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
