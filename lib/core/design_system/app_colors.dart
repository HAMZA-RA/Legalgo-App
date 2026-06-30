import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const softIndigo = Color(0xFF5B5FEF);
  static const violet = Color(0xFF7C5CFF);
  static const deepIndigo = Color(0xFF3730A3);
  static const teal = Color(0xFF14B8A6);
  static const tealSoft = Color(0xFFE6FFFB);

  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const elevatedSurface = Color(0xFFFBFCFF);
  static const border = Color(0xFFE9ECF5);

  static const navy = Color(0xFF111827);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF98A2B3);

  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFF79009);
  static const danger = Color(0xFFF04438);

  static Color pageBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B1020)
        : background;
  }

  static Color cardSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141B2D)
        : surface;
  }

  static Color subtleSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B2438)
        : elevatedSurface;
  }

  static Color subtleBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: .08)
        : border;
  }

  static LinearGradient heroGradient(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1B4B), Color(0xFF18263F), Color(0xFF0F2F35)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF3F4FF), Color(0xFFF8F5FF), Color(0xFFEFFDFC)],
    );
  }

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softIndigo, violet],
  );
}
