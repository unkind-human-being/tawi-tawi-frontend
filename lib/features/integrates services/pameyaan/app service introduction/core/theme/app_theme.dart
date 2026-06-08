import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- 1. Add this import

// 1. Centralized Custom Colors
class AppColors {
  static const Color deepOcean = Color(0xFF0B192C);
  static const Color neonTeal = Color(0xFF00FFCA);
  static const Color softBg = Color(0xFFF4F7F9);
  static const Color driverAccent = Color(0xFF10B981); 
  static const Color white = Colors.white;
  static const Color errorRed = Colors.redAccent;
  static const Color darkCard = Color(0xFF1E1E1E);

  // Dark Mode Specific Colors
  static const Color darkBg = Color(0xFF121212); 
  static const Color darkSurface = Color(0xFF1E1E1E); 
}

// 2. Global App Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.softBg,
      primaryColor: AppColors.deepOcean,
      
      // <-- 2. Apply Plus Jakarta Sans to Light Theme
      textTheme: GoogleFonts.plusJakartaSansTextTheme(), 
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepOcean,
        secondary: AppColors.neonTeal,
        tertiary: AppColors.driverAccent,
        surface: AppColors.white,
        error: AppColors.errorRed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.deepOcean,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, 
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.neonTeal, 
      
      // <-- 3. Apply Plus Jakarta Sans to Dark Theme (merging with default dark text colors)
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonTeal, 
        secondary: AppColors.deepOcean,
        tertiary: AppColors.driverAccent,
        surface: AppColors.darkSurface,
        error: AppColors.errorRed,
        onPrimary: AppColors.deepOcean, 
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.neonTeal, 
          foregroundColor: AppColors.deepOcean, 
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
    );
  }
}

// 3. THE MAGIC SYSTEM-AWARE EXTENSION 
extension ThemeHelper on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get dynamicText => isDarkMode ? Colors.white : AppColors.deepOcean;
  Color get dynamicCard => isDarkMode ? AppColors.darkSurface : Colors.white;
  Color get dynamicMuted => isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get dynamicBorder => isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
}