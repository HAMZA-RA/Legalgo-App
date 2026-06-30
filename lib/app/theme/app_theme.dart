import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _primary = Color(0xFF5B5CF6);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _violet = Color(0xFF7C5CFA);
  static const Color _ink = Color(0xFF111827);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primary,
          secondary: _teal,
          tertiary: _violet,
          surface: const Color(0xFFF7F8FC),
          onSurface: _ink,
        );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      cardColor: Colors.white,
    );
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFA5B4FC),
          secondary: const Color(0xFF5EEAD4),
          tertiary: const Color(0xFFC4B5FD),
          surface: const Color(0xFF121821),
          onSurface: const Color(0xFFE5E7EB),
        );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      cardColor: const Color(0xFF161B22),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Roboto',
      textTheme: Typography.material2021().black.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
