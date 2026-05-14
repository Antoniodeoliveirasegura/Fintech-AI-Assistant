import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_preference_store.dart';

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPrefsThemePreferenceStore(),
);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.watch(themePreferenceStoreProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._store) : super(ThemeMode.light) {
    _restore();
  }

  final ThemePreferenceStore _store;

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> _restore() async {
    final isDarkMode = await _store.readIsDarkMode();
    if (mounted) {
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = nextMode;
    await _store.writeIsDarkMode(nextMode == ThemeMode.dark);
  }
}
