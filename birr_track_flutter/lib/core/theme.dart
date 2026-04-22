import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 32, color: primaryText),
      displayMedium: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 26, color: primaryText),
      displaySmall: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 22, color: primaryText),
      headlineMedium: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 18, color: primaryText),
      headlineSmall: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 17, color: primaryText),
      titleLarge: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 16, color: primaryText),
      titleMedium: GoogleFonts.rubik(fontWeight: FontWeight.w500, fontSize: 15, color: primaryText),
      titleSmall: GoogleFonts.rubik(fontWeight: FontWeight.w500, fontSize: 14, color: primaryText),
      bodyLarge: GoogleFonts.rubik(fontWeight: FontWeight.w400, fontSize: 16, color: primaryText),
      bodyMedium: GoogleFonts.rubik(fontWeight: FontWeight.w400, fontSize: 14, color: primaryText),
      bodySmall: GoogleFonts.rubik(fontWeight: FontWeight.w400, fontSize: 13, color: secondaryText),
      labelLarge: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 14, color: primaryText),
      labelMedium: GoogleFonts.rubik(fontWeight: FontWeight.w500, fontSize: 13, color: primaryText),
      labelSmall: GoogleFonts.rubik(fontWeight: FontWeight.w500, fontSize: 12, color: secondaryText),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        surfaceContainerHighest: AppColors.surfaceSecondary,
        error: AppColors.expense,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(AppColors.text, AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.rubik(
          fontWeight: FontWeight.w700,
          fontSize: 26,
          color: AppColors.text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.navInactive, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.primary);
          }
          return GoogleFonts.rubik(fontWeight: FontWeight.w500, fontSize: 11, color: AppColors.navInactive);
        }),
        elevation: 8,
        shadowColor: AppColors.primary.withOpacity(0.08),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        hintStyle: GoogleFonts.rubik(color: AppColors.textTertiary),
        labelStyle: GoogleFonts.rubik(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          textStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary.withOpacity(0.4) : AppColors.textTertiary.withOpacity(0.3)),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        surfaceContainerHighest: AppColors.darkSurfaceSecondary,
        error: AppColors.expense,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(AppColors.darkText, AppColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.rubik(
          fontWeight: FontWeight.w700,
          fontSize: 26,
          color: AppColors.darkText,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primaryLight.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 24);
          }
          return IconThemeData(color: AppColors.darkTextSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.primaryLight);
          }
          return GoogleFonts.rubik(fontWeight: FontWeight.w500, fontSize: 11, color: AppColors.darkTextSecondary);
        }),
        elevation: 8,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
        hintStyle: GoogleFonts.rubik(color: AppColors.darkTextSecondary),
        labelStyle: GoogleFonts.rubik(color: AppColors.darkTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.textInverse,
          textStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.darkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryLight.withOpacity(0.4) : AppColors.darkTextSecondary.withOpacity(0.3)),
      ),
    );
  }
}
