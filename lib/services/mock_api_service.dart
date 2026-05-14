import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/chat_message.dart';

// Simulates network latency so UI loading states are exercised.
Future<T> _delay<T>(T value, {int ms = 800}) =>
    Future.delayed(Duration(milliseconds: ms), () => value);

// ---------------------------------------------------------------------------
// Static seed data — replace these Maps with real API responses later.
// ---------------------------------------------------------------------------

final _userData = {
  'id': 'usr_001',
  'name': 'Jordan Rivera',
  'email': 'jordan.rivera@email.com',
  'phone': '+1 (305) 555-0192',
  'member_since': '2022-03-15',
};

final _loanData = {
  'id': 'loan_001',
  'user_id': 'usr_001',
  'principal_amount': 25000.0,
  'remaining_balance': 18340.50,
  'interest_rate': 8.5,
  'start_date': '2023-01-01',
  'end_date': '2027-01-01',
  'next_payment_date': '2026-06-01',
  'monthly_payment': 615.23,
  'status': 'active',
  'total_payments': 48,
  'completed_payments': 16,
};

final _paymentsData = [
  {
    'id': 'pay_016',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-05-01',
    'paid_date': '2026-05-01',
    'status': 'paid',
  },
  {
    'id': 'pay_015',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-04-01',
    'paid_date': '2026-04-02',
    'status': 'paid',
  },
  {
    'id': 'pay_014',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-03-01',
    'paid_date': '2026-03-01',
    'status': 'paid',
  },
  {
    'id': 'pay_013',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-02-01',
    'paid_date': '2026-02-05',
    'status': 'paid',
  },
  {
    'id': 'pay_012',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-01-01',
    'paid_date': null,
    'status': 'late',
  },
  {
    'id': 'pay_017',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-06-01',
    'paid_date': null,
    'status': 'upcoming',
  },
  {
    'id': 'pay_018',
    'loan_id': 'loan_001',
    'amount': 615.23,
    'due_date': '2026-07-01',
    'paid_date': null,
    'status': 'upcoming',
  },
];

// ---------------------------------------------------------------------------
// MockApiService
// ---------------------------------------------------------------------------

class MockApiService {
  // Singleton so all providers share the same instance.
  static final MockApiService _instance = MockApiService._();
  factory MockApiService() => _instance;
  MockApiService._();

  Future<User> getCurrentUser() async {
    return _delay(User.fromJson(_userData));
  }

  Future<Loan> getLoan() async {
    return _delay(Loan.fromJson(_loanData));
  }

  Future<List<Payment>> getPayments() async {
    final payments = _paymentsData.map((p) => Payment.fromJson(p)).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate)); // newest first
    return _delay(payments);
  }

  // Simulates a session login — returns the user on success.
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }
    // In production this would POST to /api/auth/login
    return User.fromJson(_userData);
  }

  // Delegates to AiAssistantService — kept here so callers only depend on
  // one service class.
  Future<ChatMessage> sendChatMessage(String message) async {
    final response = await AiAssistantService._respond(message);
    return _delay(response, ms: 600);
  }
}

// ---------------------------------------------------------------------------
// AiAssistantService
// Keyword-matching engine — swap _respond() body for a real LLM call later.
// ---------------------------------------------------------------------------

class AiAssistantService {
  AiAssistantService._(); // not instantiated directly

  static final _currency = NumberFormat.currency(symbol: '\$');
  static final _date = DateFormat('MMMM d, yyyy');

  static Future<ChatMessage> _respond(String userMessage) async {
    final loan = Loan.fromJson(_loanData);
    final payments = _paymentsData.map((p) => Payment.fromJson(p)).toList();
    final latePayments =
        payments.where((p) => p.status == PaymentStatus.late).toList();
    final upcomingPayments =
        payments.where((p) => p.status == PaymentStatus.upcoming).toList();
    final recentPaid = payments
        .where((p) => p.status == PaymentStatus.paid)
        .take(3)
        .toList();

    final msg = userMessage.toLowerCase();
    final String reply;

    if (_matches(msg, ['balance', 'owe', 'remaining', 'left'])) {
      reply =
          'Your current loan balance is ${_currency.format(loan.remainingBalance)}. '
          'You started with ${_currency.format(loan.principalAmount)} and '
          'have paid off ${_currency.format(loan.amountPaid)} so far. '
          "You're ${(loan.progressFraction * 100).toStringAsFixed(0)}% of the way through your loan.";
    } else if (_matches(msg, ['next payment', 'due', 'when'])) {
      reply =
          'Your next payment of ${_currency.format(loan.monthlyPayment)} is due on '
          '${_date.format(loan.nextPaymentDate)}. '
          'Make sure your account is funded before that date.';
    } else if (_matches(msg, ['late', 'overdue', 'missed'])) {
      if (latePayments.isEmpty) {
        reply = "Great news — you have no late payments on record. Keep it up!";
      } else {
        final details = latePayments
            .map((p) =>
                '• ${_currency.format(p.amount)} due ${_date.format(p.dueDate)}')
            .join('\n');
        reply =
            'You have ${latePayments.length} late payment(s):\n$details\n\n'
            'Late payments can affect your credit score. Contact support to discuss a payment plan.';
      }
    } else if (_matches(msg, ['summarize', 'summary', 'overview', 'about my loan'])) {
      reply = 'Here\'s a summary of your loan:\n\n'
          '• Principal: ${_currency.format(loan.principalAmount)}\n'
          '• Remaining balance: ${_currency.format(loan.remainingBalance)}\n'
          '• Interest rate: ${loan.interestRate}% APR\n'
          '• Monthly payment: ${_currency.format(loan.monthlyPayment)}\n'
          '• Status: ${loan.status.label}\n'
          '• Progress: ${loan.completedPayments} of ${loan.totalPayments} payments completed\n'
          '• Loan ends: ${_date.format(loan.endDate)}';
    } else if (_matches(msg, ['recent payment', 'last payment', 'history'])) {
      if (recentPaid.isEmpty) {
        reply = 'No payments have been made yet.';
      } else {
        final details = recentPaid
            .map((p) =>
                '• ${_currency.format(p.amount)} — paid ${_date.format(p.paidDate!)}')
            .join('\n');
        reply = 'Your 3 most recent payments:\n$details';
      }
    } else if (_matches(msg, ['upcoming', 'schedule', 'future payment'])) {
      if (upcomingPayments.isEmpty) {
        reply = 'No upcoming payments found.';
      } else {
        final details = upcomingPayments
            .take(3)
            .map((p) =>
                '• ${_currency.format(p.amount)} due ${_date.format(p.dueDate)}')
            .join('\n');
        reply = 'Upcoming payments:\n$details';
      }
    } else if (_matches(msg, ['interest', 'rate', 'apr'])) {
      reply =
          'Your loan carries an interest rate of ${loan.interestRate}% APR. '
          'Of your ${_currency.format(loan.monthlyPayment)} monthly payment, '
          'a portion goes toward interest and the rest reduces your principal.';
    } else if (_matches(msg, ['hello', 'hi', 'hey', 'help'])) {
      reply = 'Hi there! I\'m your Fintech AI Assistant. You can ask me:\n\n'
          '• "What is my balance?"\n'
          '• "When is my next payment?"\n'
          '• "Do I have any late payments?"\n'
          '• "Summarize my loan"\n'
          '• "Show my recent payments"\n'
          '• "What\'s my interest rate?"';
    } else {
      reply =
          'I\'m not sure how to answer that yet. Try asking about your balance, '
          'next payment date, late payments, or ask me to summarize your loan.';
    }

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: reply,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  // Returns true if the message contains any of the given keywords.
  static bool _matches(String message, List<String> keywords) {
    return keywords.any((kw) => message.contains(kw));
  }
}
