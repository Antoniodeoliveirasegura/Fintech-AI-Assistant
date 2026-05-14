// Tests for authProvider.
//
// Pattern to remember: in Riverpod tests, you create your own
// `ProviderContainer`, read providers off it, and dispose it in tearDown.
// You don't need a widget tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintech_ai_assistant/providers/auth_provider.dart';

void main() {
  group('authProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is unauthenticated', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });

    test('login with valid credentials sets the user', () async {
      await container
          .read(authProvider.notifier)
          .login('test@example.com', 'password123');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, isNotNull);
      expect(state.user!.email, contains('@'));
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });

    test('login with empty credentials sets an error', () async {
      await container.read(authProvider.notifier).login('', '');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('logout clears the user', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.login('test@example.com', 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      notifier.logout();

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.error, isNull);
    });

    test('subsequent login after error clears the error', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.login('', ''); // fails
      expect(container.read(authProvider).error, isNotNull);

      await notifier.login('a@b.com', 'password123');
      expect(container.read(authProvider).error, isNull);
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });
  });
}
