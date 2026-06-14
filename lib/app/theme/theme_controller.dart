import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'legalgo_theme_mode';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return ThemeController(prefs);
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._preferences) : super(_readInitialMode(_preferences));

  final SharedPreferences? _preferences;

  static ThemeMode _readInitialMode(SharedPreferences? preferences) {
    final value = preferences?.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _preferences?.setString(_themeModeKey, mode.name);
  }
}
