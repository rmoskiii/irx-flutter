import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared design tokens for the app shell (home hub, navigation, cards).
/// Individual districts layer their own accent on top of this via
/// [DistrictTheme] - the shell itself stays constant so the app never
/// feels cluttered even as districts get more visually distinct.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF17171A);
  static const Color surfaceRaised = Color(0xFF1D1D20);
  static const Color border = Color(0xFF232326);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8A8A90);
  static const Color textMuted = Color(0xFF5A5A60);

  static const Color violet = Color(0xFFB78CFF);
  static const Color amber = Color(0xFFFFC15E);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF5EE6A0);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final headingFont = GoogleFonts.spaceGrotesk();
    final bodyFont = GoogleFonts.inter();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.violet,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            fontFamily: bodyFont.fontFamily,
          )
          .copyWith(
            displayLarge: headingFont.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
            titleLarge: headingFont.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            titleMedium: headingFont.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            bodyLarge: bodyFont.copyWith(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
            bodyMedium: bodyFont.copyWith(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
            labelSmall: bodyFont.copyWith(
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}

/// Reusable soft radial glow used behind hero content on several screens.
/// Kept as a single shared widget so the "glow" language stays consistent
/// instead of every screen inventing its own gradient.
class AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const AmbientGlow({super.key, required this.color, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.22), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}
