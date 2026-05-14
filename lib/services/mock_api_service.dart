import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/chat_message.dart';

// ============================================================================
// MockApiService — drop-in stand-in for the future Django REST backend.
//
// Every method here mirrors what a real `RemoteApiService` would do:
//   getCurrentUser()    -> GET  /api/v1/users/me
//   getLoan()           -> GET  /api/v1/loans/active
//   getPayments()       -> GET  /api/v1/loans/{id}/payments
//   login()             -> POST /api/v1/auth/login
//   sendChatMessage()   -> POST /api/v1/assistant/messages
//
// To migrate to a real backend:
//   1. Wire HttpApiClient (see lib/services/api_client.dart).
//   2. Create RemoteApiService with the same public method signatures.
//   3. Replace `MockApiService()` callers, or introduce an `apiServiceProvider`
//      Riverpod provider that returns the chosen implementation.
//
// The keyword-matching AiAssistantService is a temporary stand-in for an LLM
// agent. See `AiAssistantService._respond` for swap-in instructions.
// ============================================================================

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

// TODO(django-backend): create `RemoteApiService` next to this class that
//   implements the same 5 methods using ApiClient. Then expose an
//   `apiServiceProvider` that returns one or the other based on a build flag.
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
// AiAssistantService — keyword-matching stand-in for a real LLM agent.
//
// LLM SWAP-IN
// To replace with a real model (OpenAI, Anthropic, on-prem Ollama, etc.):
//   1. Replace the body of _respond() with an HTTP call that includes the
//      user message + a system prompt containing the loan/payments JSON.
//   2. Move the prompt construction into a `PromptBuilder` class so the
//      "tools" the model can call (getBalance, getPayments) stay testable.
//   3. Keep the public signature `Future<ChatMessage> _respond(String)` so
//      MockApiService.sendChatMessage doesn't change.
//
// Order of branches matters: more specific patterns come first to win over
// the generic ones (e.g. "paid so far" before "paid").
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
    final reply = _buildReply(
      msg: msg,
      loan: loan,
      latePayments: latePayments,
      upcomingPayments: upcomingPayments,
      recentPaid: recentPaid,
    );

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: reply,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  static String _buildReply({
    required String msg,
    required Loan loan,
    required List<Payment> latePayments,
    required List<Payment> upcomingPayments,
    required List<Payment> recentPaid,
  }) {
    // ── Specific patterns first ────────────────────────────────────────
    if (_matches(msg, [
      'what should i',
      'should i do',
      'next step',
      'recommend',
      'advice',
      'what do i do',
    ])) {
      return _nextStepAdvice(loan, latePayments);
    }

    if (_matches(msg, [
      'paid so far',
      'how much have i paid',
      'total paid',
      'amount paid',
    ])) {
      return 'You have paid ${_currency.format(loan.amountPaid)} so far. '
          'That\'s ${(loan.progressFraction * 100).toStringAsFixed(0)}% of '
          'your ${_currency.format(loan.principalAmount)} original loan, '
          'across ${loan.completedPayments} payments.';
    }

    if (_matches(msg, [
      'percent',
      'percentage',
      'progress',
      'how far',
      'how much progress',
    ])) {
      final pct = (loan.progressFraction * 100).toStringAsFixed(1);
      return 'You are $pct% through your loan — '
          '${loan.completedPayments} of ${loan.totalPayments} scheduled '
          'payments completed. At your current pace, you\'ll finish on '
          '${_date.format(loan.endDate)}.';
    }

    if (_matches(msg, ['loan status', 'my status', 'explain my', 'status'])) {
      return _explainStatus(loan);
    }

    // ── Existing patterns ──────────────────────────────────────────────
    if (_matches(msg, ['balance', 'owe', 'remaining', 'left'])) {
      return 'Your current loan balance is ${_currency.format(loan.remainingBalance)}. '
          'You started with ${_currency.format(loan.principalAmount)} and '
          'have paid off ${_currency.format(loan.amountPaid)} so far. '
          "You're ${(loan.progressFraction * 100).toStringAsFixed(0)}% of the way through your loan.";
    }

    if (_matches(msg, ['next payment', 'due', 'when'])) {
      return 'Your next payment of ${_currency.format(loan.monthlyPayment)} is due on '
          '${_date.format(loan.nextPaymentDate)}. '
          'Make sure your account is funded before that date.';
    }

    if (_matches(msg, ['late', 'overdue', 'missed'])) {
      if (latePayments.isEmpty) {
        return 'Great news — you have no late payments on record. Keep it up!';
      }
      final details = latePayments
          .map((p) =>
              '• ${_currency.format(p.amount)} due ${_date.format(p.dueDate)}')
          .join('\n');
      return 'You have ${latePayments.length} late payment(s):\n$details\n\n'
          'Late payments can affect your credit score. Contact support to discuss a payment plan.';
    }

    if (_matches(msg, ['summarize', 'summary', 'overview', 'about my loan'])) {
      return 'Here\'s a summary of your loan:\n\n'
          '• Principal: ${_currency.format(loan.principalAmount)}\n'
          '• Remaining balance: ${_currency.format(loan.remainingBalance)}\n'
          '• Interest rate: ${loan.interestRate}% APR\n'
          '• Monthly payment: ${_currency.format(loan.monthlyPayment)}\n'
          '• Status: ${loan.status.label}\n'
          '• Progress: ${loan.completedPayments} of ${loan.totalPayments} payments completed\n'
          '• Loan ends: ${_date.format(loan.endDate)}';
    }

    if (_matches(msg, ['recent payment', 'last payment', 'history'])) {
      if (recentPaid.isEmpty) return 'No payments have been made yet.';
      final details = recentPaid
          .map((p) =>
              '• ${_currency.format(p.amount)} — paid ${_date.format(p.paidDate!)}')
          .join('\n');
      return 'Your 3 most recent payments:\n$details';
    }

    if (_matches(msg, ['upcoming', 'schedule', 'future payment'])) {
      if (upcomingPayments.isEmpty) return 'No upcoming payments found.';
      final details = upcomingPayments
          .take(3)
          .map((p) =>
              '• ${_currency.format(p.amount)} due ${_date.format(p.dueDate)}')
          .join('\n');
      return 'Upcoming payments:\n$details';
    }

    if (_matches(msg, ['interest', 'rate', 'apr'])) {
      return 'Your loan carries an interest rate of ${loan.interestRate}% APR. '
          'Of your ${_currency.format(loan.monthlyPayment)} monthly payment, '
          'a portion goes toward interest and the rest reduces your principal.';
    }

    if (_matches(msg, ['hello', 'hi ', 'hey', 'help'])) {
      return 'Hi there! I\'m your Fintech AI Assistant. You can ask me:\n\n'
          '• "What is my balance?"\n'
          '• "When is my next payment?"\n'
          '• "Do I have any late payments?"\n'
          '• "How much have I paid so far?"\n'
          '• "What percentage of my loan is paid?"\n'
          '• "Explain my loan status"\n'
          '• "What should I do next?"\n'
          '• "Summarize my loan"';
    }

    return 'I\'m not sure how to answer that yet. Try asking about your '
        'balance, next payment, progress, or what to do next.';
  }

  static String _explainStatus(Loan loan) {
    switch (loan.status) {
      case LoanStatus.active:
        return 'Your loan is currently active. You have an outstanding balance '
            'of ${_currency.format(loan.remainingBalance)} and are making '
            'scheduled monthly payments. ${loan.totalPayments - loan.completedPayments} '
            'payment(s) remain over the next '
            '${((loan.totalPayments - loan.completedPayments) / 12).toStringAsFixed(1)} years.';
      case LoanStatus.paid:
        return 'Your loan is fully paid off. No further payments are due — '
            'nice work!';
      case LoanStatus.defaulted:
        return 'Your loan is in default. This is a serious status that '
            'affects your credit. Please contact our support team '
            'immediately to discuss recovery options.';
      case LoanStatus.pending:
        return 'Your loan is pending. Funds have not yet been disbursed and '
            'no payments are due. You\'ll receive an update once approval '
            'is finalized.';
    }
  }

  static String _nextStepAdvice(Loan loan, List<Payment> latePayments) {
    if (latePayments.isNotEmpty) {
      return 'Your top priority is your ${latePayments.length} late payment(s). '
          'Make at least one payment of ${_currency.format(latePayments.first.amount)} '
          'as soon as possible to limit credit impact. After that, '
          'your next scheduled payment is on ${_date.format(loan.nextPaymentDate)}.';
    }
    if (loan.status == LoanStatus.active) {
      return 'You\'re on track. Your next action is to make sure your account '
          'is funded for your '
          '${_currency.format(loan.monthlyPayment)} payment due '
          '${_date.format(loan.nextPaymentDate)}. If you haven\'t already, '
          'enabling autopay is a good idea — it avoids accidental late fees.';
    }
    if (loan.status == LoanStatus.paid) {
      return 'You\'re all done — no payments are due. Consider reviewing your '
          'credit report to confirm the paid status is reflected.';
    }
    return 'No immediate action needed. Continue checking in here for updates.';
  }

  // Returns true if the message contains any of the given keywords.
  static bool _matches(String message, List<String> keywords) {
    return keywords.any((kw) => message.contains(kw));
  }
}
