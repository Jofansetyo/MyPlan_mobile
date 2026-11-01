import 'package:flutter/material.dart';

class AppTheme {
  // Palet Warna
  static const Color paperBg = Color(0xFFE4E4E4);
  static const Color inkNavy = Color(0xFF13223F);
  static const Color inkSky = Color(0xFF559FD1);
  static const Color paleSky = Color(0xFFC4D8E4);
  static const Color panelBg = Color(0xFFF2F3F5);

  // Warna Fungsional
  static const Color incomeGreen = Color(0xFF2E7D4F);
  static const Color expenseRed = Color(0xFFB3261E);
  static const Color priorityLow = Color(0xFF2E7D4F);
  static const Color priorityMed = Color(0xFFB7791F);
  static const Color priorityHigh = Color(0xFFB3261E);

  // Dark Mode
  static const Color darkBg = Color(0xFF13223F);
  static const Color darkPanel = Color(0xFF1B2F55);
  static const Color darkText = Color(0xFFE4E4E4);

  // ==========================================
  // LIGHT THEME (SIANG)
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paperBg,
      primaryColor: inkNavy,
      colorScheme: const ColorScheme.light(
        primary: inkNavy,
        secondary: inkSky,
        surface: panelBg,
        error: expenseRed,
      ),

      // Tipografi Menggunakan Font Lokal
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: inkNavy),
        titleLarge: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: inkNavy,
            fontSize: 22),
        titleMedium: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: inkNavy,
            fontSize: 16),
        labelLarge: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: inkNavy),
        bodyLarge: TextStyle(
            fontFamily: 'FiraSans', fontSize: 16, height: 1.6, color: inkNavy),
        bodyMedium:
            TextStyle(fontFamily: 'FiraSans', fontSize: 14, color: inkNavy),
      ),

      // Kartu
      cardTheme: CardThemeData(
        color: panelBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: inkNavy, width: 1.5),
        ),
      ),

      // Tombol Utama
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkNavy,
          foregroundColor: paperBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontFamily: 'KodeMono',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          minimumSize: const Size(48, 48),
        ),
      ),

      // Tombol Outline (Batal)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkNavy,
          backgroundColor: paleSky,
          side: const BorderSide(color: inkNavy, width: 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontFamily: 'KodeMono',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }

  // ==========================================
  // DARK THEME (MALAM)
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      primaryColor: inkSky,
      colorScheme: const ColorScheme.dark(
        primary: inkSky,
        secondary: paleSky,
        surface: darkPanel,
        error: expenseRed,
      ),

      // Tipografi (Warna teks diubah jadi terang)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: darkText),
        titleLarge: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: darkText,
            fontSize: 22),
        titleMedium: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: darkText,
            fontSize: 16),
        labelLarge: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: darkText),
        bodyLarge: TextStyle(
            fontFamily: 'FiraSans', fontSize: 16, height: 1.6, color: darkText),
        bodyMedium:
            TextStyle(fontFamily: 'FiraSans', fontSize: 14, color: darkText),
      ),

      // Kartu (Warna panel gelap dengan border biru langit)
      cardTheme: CardThemeData(
        color: darkPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: inkSky, width: 1.5),
        ),
      ),

      // Tombol Utama
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkSky,
          foregroundColor: darkBg, // Teks tombol jadi navy gelap agar kontras
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontFamily: 'KodeMono',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          minimumSize: const Size(48, 48),
        ),
      ),

      // Tombol Outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          backgroundColor: darkPanel,
          side: const BorderSide(color: inkSky, width: 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontFamily: 'KodeMono',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
