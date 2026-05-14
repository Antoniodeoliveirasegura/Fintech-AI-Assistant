import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemePreferenceStore {
  Future<bool> readIsDarkMode();
  Future<void> writeIsDarkMode(bool value);
}

class SharedPrefsThemePreferenceStore implements ThemePreferenceStore {
  static const _key = 'is_dark_mode';

  @override
  Future<bool> readIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> writeIsDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class InMemoryThemePreferenceStore implements ThemePreferenceStore {
  InMemoryThemePreferenceStore({bool initialValue = false})
    : _isDarkMode = initialValue;

  bool _isDarkMode;

  @override
  Future<bool> readIsDarkMode() async => _isDarkMode;

  @override
  Future<void> writeIsDarkMode(bool value) async {
    _isDarkMode = value;
  }
}
