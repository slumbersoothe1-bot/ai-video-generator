import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide color tokens. Ultra-premium dark palette with deep navy base,
/// electric cyan and sapphire blue accents — no purple, no violet.
class AppColors {
  AppColors._();

  // Base / surfaces — layered depth system
  static const Color background = Color(0xFF050810);
  static const Color surface = Color(0xFF0B1120);
  static const Color surfaceElevated = Color(0xFF121A2E);
  static const Color card = Color(0xFF16203A);
  static const Color cardHover = Color(0xFF1C2848);
  static const Color border = Color(0xFF243056);
  static const Color borderFocused = Color(0xFF3A4A7A);

  // Brand — electric sapphire + cyan
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF00D4FF); // electric cyan
  static const Color accentSecondary = Color(0xFF06B6D4); // teal-cyan
  static const Color success = Color(0xFF10D984);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);

  // Text — high contrast for readability
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients — premium, cohesive
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
  );
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4FF), Color(0xFF2563EB)],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF050810), Color(0xFF0A0F1E)],
  );
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF00D4FF)],
  );
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1, 0),
    end: Alignment(1, 0),
    colors: [Color(0xFF121A2E), Color(0xFF243056), Color(0xFF121A2E)],
  );

  // Glass effect
  static const Color glassOverlay = Color(0x0AFFFFFF);
  static const Color glassBorder = Color(0x14FFFFFF);
}

/// Text styles using Google Fonts (Space Grotesk + Inter).
class AppText {
  AppText._();

  static TextStyle get display => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get heading => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
  );

  static TextStyle get button => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
  );

  static TextStyle get caption => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        fontSize: 12,
        height: 1.4,
  );
}

/// Semantic spacing on an 8px grid.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
}

/// Animation durations — snappy and premium, never sluggish.
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration splash = Duration(milliseconds: 800);
}

/// The Material theme data built from the tokens above.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.heading.copyWith(fontSize: 20),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputDecorationTheme(),
      filledButtonTheme: _filledButtonTheme(),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppText.button,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppText.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _ZoomUpTransitionBuilder(),
          TargetPlatform.iOS: _ZoomUpTransitionBuilder(),
        },
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
      labelStyle: AppText.label,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: AppText.button.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }
}

/// Custom page transition: a subtle zoom + fade that feels instant and premium.
class _ZoomUpTransitionBuilder extends PageTransitionsBuilder {
  const _ZoomUpTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = Curves.easeOutCubic;
    final curveAnimation = CurvedAnimation(parent: animation, curve: curve);

    return FadeTransition(
      opacity: curveAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curveAnimation),
        child: child,
      ),
    );
  }
}
