// Beginner-friendly tests for MockApiService.
//
// What these test:
//   - The service returns the expected seed data shape.
//   - Computed getters on models (Loan.progressFraction) behave correctly.
//   - login() validates inputs.
//
// These tests will keep working when MockApiService is replaced by
// RemoteApiService — they exercise the *contract*, not the implementation.

import 'package:flutter_test/flutter_test.dart';
import 'package:fintech_ai_assistant/models/loan.dart';
import 'package:fintech_ai_assistant/services/mock_api_service.dart';

void main() {
  final api = MockApiService();

  group('MockApiService', () {
    test('getCurrentUser returns the seed user', () async {
      final user = await api.getCurrentUser();
      expect(user.id, isNotEmpty);
      expect(user.name, 'Jordan Rivera');
      expect(user.email, contains('@'));
      expect(user.firstName, 'Jordan');
    });

    test('getLoan returns an active loan with sensible values', () async {
      final loan = await api.getLoan();
      expect(loan.status, LoanStatus.active);
      expect(loan.principalAmount, greaterThan(0));
      expect(loan.remainingBalance, lessThan(loan.principalAmount));
      expect(loan.progressFraction, inInclusiveRange(0.0, 1.0));
      expect(loan.completedPayments, lessThanOrEqualTo(loan.totalPayments));
    });

    test('getPayments returns payments newest-first', () async {
      final payments = await api.getPayments();
      expect(payments, isNotEmpty);
      // Each adjacent pair must be in descending order by due date.
      for (var i = 0; i < payments.length - 1; i++) {
        expect(
          payments[i].dueDate.compareTo(payments[i + 1].dueDate),
          greaterThanOrEqualTo(0),
          reason: 'payments should be sorted newest-first',
        );
      }
    });

    test('watchAccountNotifications emits live notification snapshots',
        () async {
      final firstSnapshot = await api.watchAccountNotifications().first;

      expect(firstSnapshot, hasLength(2));
      expect(firstSnapshot.first.title, isNotEmpty);
    });

    test('login throws when credentials are empty', () async {
      expect(api.login('', ''), throwsException);
    });

    test('login returns the user on valid input', () async {
      final user = await api.login('test@example.com', 'password123');
      expect(user.name, 'Jordan Rivera');
    });
  });
}
