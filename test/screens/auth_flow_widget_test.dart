import 'package:fintech_ai_assistant/main.dart';
import 'package:fintech_ai_assistant/providers/auth_provider.dart';
import 'package:fintech_ai_assistant/services/secure_token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    String? initialToken,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(
            InMemorySecureTokenStore(initialToken: initialToken),
          ),
        ],
        child: const FintechApp(),
      ),
    );
  }

  testWidgets('login screen renders when unauthenticated', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('stored token restores session and shows dashboard',
      (tester) async {
    await pumpApp(tester, initialToken: 'mock-session-token');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Jordan'), findsOneWidget);
    expect(find.text('Loan Balance'), findsOneWidget);
    expect(find.text('Next Payment'), findsOneWidget);
  });

  testWidgets('logout clears session and returns to login', (tester) async {
    await pumpApp(tester, initialToken: 'mock-session-token');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
