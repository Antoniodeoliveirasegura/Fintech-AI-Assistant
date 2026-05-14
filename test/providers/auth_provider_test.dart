// Tests for authProvider.
//
// Pattern to remember: in Riverpod tests, you create your own
// `ProviderContainer`, read providers off it, and dispose it in tearDown.
// You don't need a widget tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintech_ai_assistant/providers/auth_provider.dart';
import 'package:fintech_ai_assistant/services/secure_token_store.dart';

void main() {
  group('authProvider', () {
    late ProviderContainer container;
    late InMemorySecureTokenStore tokenStore;

    setUp(() {
      tokenStore = InMemorySecureTokenStore();
      container = ProviderContainer(
        overrides: [secureTokenStoreProvider.overrideWithValue(tokenStore)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> letRestoreFinish() async {
      await Future<void>.delayed(Duration.zero);
    }

    test('initial state is unauthenticated', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isRestoring, isTrue);
    });

    test('restoreSession keeps a stored-token user logged in', () async {
      final restoredStore = InMemorySecureTokenStore(
        initialToken: 'mock-session-token',
      );
      final restoredContainer = ProviderContainer(
        overrides: [secureTokenStoreProvider.overrideWithValue(restoredStore)],
      );
      addTearDown(restoredContainer.dispose);

      await restoredContainer.read(authProvider.notifier).restoreSession();

      final state = restoredContainer.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, isNotNull);
      expect(state.isRestoring, isFalse);
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
      expect(await tokenStore.readToken(), 'mock-session-token');
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

      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.error, isNull);
      expect(await tokenStore.readToken(), isNull);
    });

    test('subsequent login after error clears the error', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.login('', ''); // fails
      expect(container.read(authProvider).error, isNotNull);

      await notifier.login('a@b.com', 'password123');
      expect(container.read(authProvider).error, isNull);
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });

    test('restoreSession without token finishes unauthenticated', () async {
      container.read(authProvider);
      await letRestoreFinish();

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isRestoring, isFalse);
    });
  });
}
