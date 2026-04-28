import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFD4623A);
  static const accent = Color(0xFFF5A34E);
  static const bg = Color(0xFFFDF7F2);
  static const cardBg = Colors.white;
  static const border = Color(0xFFF0E4D8);
  static const chipBg = Color(0xFFF5EDE5);
  static const text = Color(0xFF1E0E04);
  static const textMuted = Color(0xFF9A7060);
  static const inputBg = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
}

// Adaptive colors — use context.cardColor, context.textColor, etc. in widgets
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get appBg => isDark ? const Color(0xFF1A0E08) : AppColors.bg;
  Color get cardColor => isDark ? const Color(0xFF2A1A10) : AppColors.cardBg;
  Color get borderColor => isDark ? const Color(0xFF3D2418) : AppColors.border;
  Color get chipColor => isDark ? const Color(0xFF2D1A10) : AppColors.chipBg;
  Color get textColor => isDark ? const Color(0xFFF5EDE5) : AppColors.text;
  Color get mutedColor => isDark ? const Color(0xFF9A7060) : AppColors.textMuted;
  Color get inputColor => isDark ? const Color(0xFF2A1A10) : AppColors.inputBg;
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: const Color(0xFF1A0E08),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A0E08),
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A0E08),
          foregroundColor: const Color(0xFFF5EDE5),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFFF5EDE5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFF5EDE5)),
        ),
        cardTheme: const CardThemeData(color: Color(0xFF2A1A10), elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A1A10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D2418), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D2418), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF9A7060), fontSize: 13),
          labelStyle: GoogleFonts.poppins(color: const Color(0xFF9A7060), fontSize: 13),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2A1A10),
          contentTextStyle: GoogleFonts.poppins(color: const Color(0xFFF5EDE5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF2A1A10),
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFFF5EDE5),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF9A7060),
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF2A1A10),
        ),
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.bg,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: AppBarTheme(
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: AppColors.text),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
          labelStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
        ),
        cardTheme: const CardThemeData(color: AppColors.cardBg, elevation: 0),
      );
}
