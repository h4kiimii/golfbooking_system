import 'package:flutter/material.dart';

class AppTheme {
  static const darkGreen = Color(0xFF147A4B);
  static const mediumGreen = Color(0xFF20A866);
  static const brightGreen = Color(0xFF39C98A);
  static const tealGreen = Color(0xFF20B8A0);
  static const lightGreen = Color(0xFFE2F8EC);
  static const softGreen = Color(0xFFF3FCF7);
  static const charcoal = Color(0xFF1F2933);
  static const darkSurface = Color(0xFF111816);
  static const darkCard = Color(0xFF1A2A24);

  static const primaryGradient = LinearGradient(
    colors: [mediumGreen, tealGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [darkGreen, mediumGreen, brightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softGradient = LinearGradient(
    colors: [Color(0xFFE2F8EC), Color(0xFFE5FAF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: mediumGreen,
      primary: mediumGreen,
      secondary: tealGreen,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightGreen.withValues(alpha: 0.94),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: mediumGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.18);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return Colors.white.withValues(alpha: 0.1);
                }
                return null;
              }),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return 0;
                if (states.contains(WidgetState.hovered)) return 2;
                return 0;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: darkGreen,
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              side: const BorderSide(color: mediumGreen),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return mediumGreen.withValues(alpha: 0.16);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return mediumGreen.withValues(alpha: 0.08);
                }
                return null;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: darkGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return mediumGreen.withValues(alpha: 0.14);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return mediumGreen.withValues(alpha: 0.08);
                }
                return null;
              }),
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: darkGreen).copyWith(
          animationDuration: const Duration(milliseconds: 180),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return mediumGreen.withValues(alpha: 0.16);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return mediumGreen.withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4FFF8).withValues(alpha: 0.94),
        labelStyle: const TextStyle(
          color: Color(0xFF20342C),
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF062D1C),
          fontWeight: FontWeight.w800,
        ),
        hintStyle: TextStyle(color: charcoal.withValues(alpha: 0.72)),
        prefixIconColor: darkGreen,
        suffixIconColor: darkGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4F4EA), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4F4EA), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: mediumGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: mediumGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: charcoal,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: charcoal,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: charcoal,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(color: charcoal, height: 1.4, letterSpacing: 0),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: mediumGreen,
      brightness: Brightness.dark,
      primary: brightGreen,
      secondary: tealGreen,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1210),
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF0F1714),
        foregroundColor: brightGreen,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: brightGreen,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: mediumGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.18);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return Colors.white.withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: brightGreen,
              side: const BorderSide(color: mediumGreen),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return mediumGreen.withValues(alpha: 0.18);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return mediumGreen.withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: brightGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return mediumGreen.withValues(alpha: 0.18);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return mediumGreen.withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: brightGreen).copyWith(
          animationDuration: const Duration(milliseconds: 180),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return mediumGreen.withValues(alpha: 0.18);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return mediumGreen.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF14211D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brightGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F1714),
        selectedItemColor: brightGreen,
        unselectedItemColor: Color(0xFF8EA097),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1E2C27),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFEAF4EF),
          height: 1.4,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
