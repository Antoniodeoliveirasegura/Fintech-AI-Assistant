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
  int _version = 0;

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> _restore() async {
    final restoreVersion = _version;
    final isDarkMode = await _store.readIsDarkMode();
    if (mounted && restoreVersion == _version) {
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    _version++;
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = nextMode;
    await _store.writeIsDarkMode(nextMode == ThemeMode.dark);
  }
}
