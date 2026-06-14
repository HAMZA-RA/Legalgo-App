import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _navy = Color(0xFF17324D);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _gold = Color(0xFFB78B2A);
  static const Color _ink = Color(0xFF111827);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: _navy,
      secondary: _teal,
      tertiary: _gold,
      surface: const Color(0xFFF7F8FA),
      onSurface: _ink,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      cardColor: Colors.white,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF9CC9FF),
      secondary: const Color(0xFF5EEAD4),
      tertiary: const Color(0xFFF2C86B),
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
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
