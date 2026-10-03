import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary — warm teal, coastal water
  static const primary = Color(0xFF0D9488);       // teal-600
  static const primaryLight = Color(0xFF2DD4BF);  // teal-400
  static const primaryDark = Color(0xFF0F766E);   // teal-700

  // Accent — sunset warmth
  static const accent = Color(0xFFF59E0B);        // amber-500
  static const accentLight = Color(0xFFFBBF24);   // amber-400
  static const accentDark = Color(0xFFD97706);     // amber-600

  // Extended accent palette
  static const purple = Color(0xFFA78BFA);   // violet-400
  static const pink = Color(0xFFF472B6);     // pink-400
  static const orange = Color(0xFFFB923C);   // orange-400
  static const cyan = Color(0xFF22D3EE);     // cyan-400

  // Achievement Tiers — richer, more distinctive
  static const bronze = Color(0xFFB87333);
  static const silver = Color(0xFF9CAAB8);
  static const gold = Color(0xFFE6B422);
  static const platinum = Color(0xFFD4CFC9);

  // Status
  static const success = Color(0xFF34D399);  // emerald-400
  static const warning = Color(0xFFFBBF24);  // amber-400
  static const error = Color(0xFFF87171);    // red-400
  static const info = Color(0xFF38BDF8);     // sky-400

  // XP — luminous emerald
  static const xpGreen = Color(0xFF34D399);
  static const xpGlow = Color(0xFF6EE7B7);

  // Background — deep ocean midnight
  static const bgDark = Color(0xFF0B1120);      // rich navy-black
  static const bgCard = Color(0xFF131C2E);      // slightly lifted navy
  static const bgCardLight = Color(0xFF1E2A3F); // muted slate-navy
  static const bgSurface = Color(0xFF131C2E);

  // Text
  static const textPrimary = Color(0xFFF0F4F8);  // warm white
  static const textSecondary = Color(0xFF8899A6); // slate-blue-muted
  static const textMuted = Color(0xFF4E6378);     // deep slate
}

class AppGradients {
  /// Main brand gradient — teal → cyan
  static const gradientPrimary = LinearGradient(
    colors: [AppColors.primary, AppColors.cyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Warm gradient — amber → orange → pink (XP / rewards)
  static const gradientWarm = LinearGradient(
    colors: [AppColors.accent, AppColors.orange, AppColors.pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Cool gradient — purple → primary → cyan (skills / level)
  static const gradientCool = LinearGradient(
    colors: [AppColors.purple, AppColors.primary, AppColors.cyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Subtle gradient for card backgrounds
  static const gradientSubtle = LinearGradient(
    colors: [AppColors.bgCard, AppColors.bgCardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Factory for tinted card backgrounds
  static LinearGradient cardGradient(Color accent) {
    return LinearGradient(
      colors: [
        accent.withValues(alpha: 0.08),
        AppColors.bgCard,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class AppShadows {
  /// Colored glow shadow for emphasis elements
  static List<BoxShadow> glowShadow(Color color, {double blur = 20, double spread = -2}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.35),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}

/// Spacing scale — use these instead of magic numbers so screens line up.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  /// Default horizontal screen padding.
  static const double page = 20;
}

/// Corner radius scale.
abstract final class AppRadius {
  static const double chip = 12;
  static const double button = 14;
  static const double card = 18;
  static const double sheet = 28;
}

/// Motion tokens — shared durations and curves so the whole app moves with
/// one voice. `emphasized` is for large surfaces (sheets, page transitions),
/// `standard` for in-place state changes, `quick` for taps/toggles.
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 380);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
}

class AppTheme {
  static ThemeData get darkTheme {
    final displayFont = GoogleFonts.plusJakartaSans();
    final bodyFont = GoogleFonts.plusJakartaSans();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgCard,
        onSurface: AppColors.textPrimary,
        tertiary: AppColors.accent,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ).copyWith(
        headlineLarge: displayFont.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: displayFont.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: displayFont.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: bodyFont.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: AppColors.textPrimary),
        side: BorderSide(color: AppColors.bgCardLight.withValues(alpha: 0.8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            );
          }
          return TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.6),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }
}
