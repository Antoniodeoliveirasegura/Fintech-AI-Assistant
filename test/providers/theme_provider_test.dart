import 'package:fintech_ai_assistant/providers/theme_provider.dart';
import 'package:fintech_ai_assistant/services/theme_preference_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('themeModeProvider', () {
    test('restores saved dark mode preference', () async {
      final container = ProviderContainer(
        overrides: [
          themePreferenceStoreProvider.overrideWithValue(
            InMemoryThemePreferenceStore(initialValue: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggle persists the next mode', () async {
      final store = InMemoryThemePreferenceStore();
      final container = ProviderContainer(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).toggle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(await store.readIsDarkMode(), isTrue);
    });
  });
}
