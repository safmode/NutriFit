import 'package:flutter/material.dart';

class AppColors {
  // Core (from your mockups)
  static const primary = Color(0xFF92A3FD);
  static const secondary = Color(0xFF9DCEFF);
  static const accent = Color(0xFFC58BF2);

  // UI surfaces
  static const bg = Colors.white;
  static const card = Color(0xFFF7F8F8);
  static const softBlue = Color(0xFFE8EEFF);

  // Text
  static const text = Color(0xFF1D1D1D);
  static const subText = Color(0xFF8E8E8E);

  static const success = Color(0xFF34C759);
  static const danger = Color(0xFFFF6B6B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Fix: withOpacity() deprecated -> use withValues(alpha: ...)
  static List<BoxShadow> softShadow({double opacity = 0.08}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
  static const black = Color(0xFF1D1617);
  static const gray = Color(0xFF7B6F72);
  static const white = Colors.white;
  static const borderColor = Color(0xFFF7F8F8);
}

class AppRadii {
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
  static const r18 = Radius.circular(18);
  static const r20 = Radius.circular(20);
  static const r24 = Radius.circular(24);

  static BorderRadius br12 = BorderRadius.circular(12);
  static BorderRadius br16 = BorderRadius.circular(16);
  static BorderRadius br18 = BorderRadius.circular(18);
  static BorderRadius br20 = BorderRadius.circular(20);
  static BorderRadius br24 = BorderRadius.circular(24);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.bg,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.subText,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.text),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadii.r24),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadii.r18),
        ),
      ),
    );
  }
}
