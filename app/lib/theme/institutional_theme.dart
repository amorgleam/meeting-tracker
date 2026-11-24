import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InstitutionalTheme {
  // Institutional Color Palette
  static const Color primaryNavy = Color(0xFF1F3A5F);
  static const Color navyLight = Color(0xFF2C4F7C);
  static const Color navyDark = Color(0xFF12243C);
  
  static const Color creamBackground = Color(0xFFFAF7F0);
  static const Color creamSurface = Color(0xFFF3EFE6);
  static const Color creamCard = Color(0xFFFCFAF5);

  static const Color goldAccent = Color(0xFFB8923A);
  static const Color goldLight = Color(0xFFDCC178);
  static const Color goldDark = Color(0xFF8C6D27);

  static const Color textDark = Color(0xFF1F2421);
  static const Color textBody = Color(0xFF333B42);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color borderLedger = Color(0xFFDDD5C7);
  static const Color borderLight = Color(0xFFE9E4D8);
  static const Color borderAccent = Color(0xFFB8923A);

  // Status Colors (Mandated)
  static const Color statusPending = Color(0xFF7C3AED);     // Regal Purple
  static const Color statusInProgress = Color(0xFFCA8A04);  // Yellow / Amber
  static const Color statusCompleted = Color(0xFF16A34A);   // Green
  static const Color statusEliminated = Color(0xFFDC2626);  // Red
  static const Color statusOverride = Color(0xFF9F1239);    // Executive Crimson (Audit flag)

  // Status Light Backgrounds
  static const Color bgPending = Color(0xFFF3E8FF);
  static const Color bgInProgress = Color(0xFFFEF9C3);
  static const Color bgCompleted = Color(0xFFDCFCE7);
  static const Color bgEliminated = Color(0xFFFEE2E2);
  static const Color bgOverride = Color(0xFFFFE4E6);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        return statusInProgress;
      case 'completed':
        return statusCompleted;
      case 'eliminated':
      case 'cancelled':
        return statusEliminated;
      case 'pending':
      default:
        return statusPending;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        return bgInProgress;
      case 'completed':
        return bgCompleted;
      case 'eliminated':
      case 'cancelled':
        return bgEliminated;
      case 'pending':
      default:
        return bgPending;
    }
  }

  static ThemeData get themeData {
    final baseFont = GoogleFonts.sourceSans3TextTheme();
    final serifFont = GoogleFonts.playfairDisplayTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        onPrimary: Colors.white,
        secondary: goldAccent,
        onSecondary: Colors.white,
        surface: creamSurface,
        onSurface: textDark,
        error: statusEliminated,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.sourceSans3().fontFamily,
      textTheme: baseFont.copyWith(
        displayLarge: serifFont.displayLarge?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        displayMedium: serifFont.displayMedium?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: serifFont.displaySmall?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: serifFont.headlineLarge?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: serifFont.headlineMedium?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: serifFont.headlineSmall?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: serifFont.titleLarge?.copyWith(
          color: primaryNavy,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseFont.titleMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: baseFont.titleSmall?.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        bodyLarge: baseFont.bodyLarge?.copyWith(
          color: textBody,
          fontSize: 15,
        ),
        bodyMedium: baseFont.bodyMedium?.copyWith(
          color: textBody,
          fontSize: 14,
        ),
        bodySmall: baseFont.bodySmall?.copyWith(
          color: textMuted,
          fontSize: 12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: creamBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: creamBackground,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: borderLedger, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLedger,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: borderLedger, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: borderLedger, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: primaryNavy, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: const BorderSide(color: primaryNavy, width: 1),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: primaryNavy, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(creamSurface),
        headingTextStyle: const TextStyle(
          color: primaryNavy,
          fontWeight: FontWeight.w700,
          fontFamily: 'serif',
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFF0EAE1);
          }
          return Colors.white;
        }),
        dataTextStyle: const TextStyle(
          color: textDark,
          fontSize: 13,
        ),
        dividerThickness: 1,
      ),
    );
  }
}
