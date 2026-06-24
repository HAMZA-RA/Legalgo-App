import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? .26 : .055),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ];
  }

  static List<BoxShadow> elevated(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? .34 : .075),
        blurRadius: 34,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static List<BoxShadow> none = const [];
}
