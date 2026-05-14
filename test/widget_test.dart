import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintech_ai_assistant/main.dart';
import 'package:fintech_ai_assistant/providers/auth_provider.dart';
import 'package:fintech_ai_assistant/services/secure_token_store.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(
            InMemorySecureTokenStore(),
          ),
        ],
        child: const FintechApp(),
      ),
    );
    expect(find.byType(FintechApp), findsOneWidget);
  });
}
