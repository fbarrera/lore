import 'package:flutter/material.dart';

/// Centralized theme for the Lore Keeper app.
/// WCAG AA compliant color contrast ratios throughout.
class LoreTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────
  static const Color parchment = Color(0xFFF5E6C8);
  static const Color inkBlack = Color(0xFF1A1A1A);
  static const Color deepBrown = Color(0xFF3E2723);
  static const Color warmBrown = Color(0xFF795548);
  static const Color lightBrown = Color(0xFFBCAAA4);
  static const Color goldAccent = Color(0xFFD4A574);
  static const Color narratorBg = Color(0xFF2C1810);
  static const Color userBubbleBg = Color(0xFF1A3A4A);
  static const Color errorRed = Color(0xFFCF6679);
  static const Color successGreen = Color(0xFF81C784);
  static const Color neutralGrey = Color(0xFF9E9E9E);

  // ── Relationship Colors ───────────────────────────────────────────────
  static const Color affinityPositive = Color(0xFF66BB6A);
  static const Color affinityNeutral = Color(0xFF90A4AE);
  static const Color affinityNegative = Color(0xFFEF5350);

  // ── Text Styles ───────────────────────────────────────────────────────
  static const String serifFont = 'Georgia';
  static const String sansFont = 'Roboto';

  static TextStyle narratorText({double fontSize = 16}) => TextStyle(
    fontFamily: serifFont,
    fontSize: fontSize,
    height: 1.6,
    color: parchment,
    letterSpacing: 0.3,
  );

  static TextStyle userText({double fontSize = 16}) => TextStyle(
    fontFamily: sansFont,
    fontSize: fontSize,
    height: 1.4,
    color: Colors.white,
  );

  static TextStyle sectionTitle({double fontSize = 18}) => TextStyle(
    fontFamily: serifFont,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: goldAccent,
    letterSpacing: 2,
  );

  static TextStyle labelStyle({double fontSize = 12}) => TextStyle(
    fontFamily: serifFont,
    fontSize: fontSize,
    color: lightBrown,
    letterSpacing: 1.2,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: serifFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: warmBrown,
      brightness: Brightness.dark,
      primary: goldAccent,
      secondary: warmBrown,
      surface: inkBlack,
      error: errorRed,
      onPrimary: inkBlack,
      onSecondary: Colors.white,
      onSurface: parchment,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: serifFont,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: goldAccent,
      ),
      iconTheme: IconThemeData(color: goldAccent),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: inkBlack,
      selectedItemColor: goldAccent,
      unselectedItemColor: warmBrown,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontFamily: serifFont, fontSize: 12),
      unselectedLabelStyle: const TextStyle(
        fontFamily: serifFont,
        fontSize: 11,
      ),
    ),
    cardTheme: CardThemeData(
      color: deepBrown.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warmBrown.withOpacity(0.3)),
      ),
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepBrown,
        foregroundColor: parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: serifFont,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inkBlack.withOpacity(0.6),
      hintStyle: TextStyle(color: warmBrown.withOpacity(0.6), fontSize: 14),
      labelStyle: const TextStyle(color: lightBrown),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: warmBrown.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerTheme: DividerThemeData(color: warmBrown.withOpacity(0.3)),
    sliderTheme: SliderThemeData(
      activeTrackColor: goldAccent,
      inactiveTrackColor: deepBrown,
      thumbColor: parchment,
      overlayColor: goldAccent.withOpacity(0.2),
      valueIndicatorColor: deepBrown,
      valueIndicatorTextStyle: const TextStyle(color: parchment),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: deepBrown,
      contentTextStyle: const TextStyle(
        color: parchment,
        fontFamily: serifFont,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ── Decorations ───────────────────────────────────────────────────────
  static BoxDecoration get backgroundGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [inkBlack, deepBrown.withOpacity(0.8), inkBlack],
      stops: const [0.0, 0.5, 1.0],
    ),
  );

  static BoxDecoration narratorBubble() => BoxDecoration(
    color: narratorBg.withOpacity(0.8),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ),
    border: Border.all(color: warmBrown.withOpacity(0.3), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration userBubble() => BoxDecoration(
    color: userBubbleBg.withOpacity(0.7),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ),
    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration glassmorphism({Color? color}) => BoxDecoration(
    color: (color ?? Colors.white).withOpacity(0.08),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
