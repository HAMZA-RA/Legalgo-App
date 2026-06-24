import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get chip => BorderRadius.circular(pill);
  static BorderRadius get icon => BorderRadius.circular(md);
}
