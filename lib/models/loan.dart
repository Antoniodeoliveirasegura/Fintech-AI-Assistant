enum LoanStatus { active, paid, defaulted, pending }

extension LoanStatusLabel on LoanStatus {
  String get label {
    switch (this) {
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.paid:
        return 'Paid Off';
      case LoanStatus.defaulted:
        return 'Defaulted';
      case LoanStatus.pending:
        return 'Pending';
    }
  }
}

class Loan {
  final String id;
  final String userId;
  final double principalAmount;
  final double remainingBalance;
  final double interestRate; // annual percentage, e.g. 8.5
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextPaymentDate;
  final double monthlyPayment;
  final LoanStatus status;
  final int totalPayments;
  final int completedPayments;

  const Loan({
    required this.id,
    required this.userId,
    required this.principalAmount,
    required this.remainingBalance,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.nextPaymentDate,
    required this.monthlyPayment,
    required this.status,
    required this.totalPayments,
    required this.completedPayments,
  });

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        principalAmount: (json['principal_amount'] as num).toDouble(),
        remainingBalance: (json['remaining_balance'] as num).toDouble(),
        interestRate: (json['interest_rate'] as num).toDouble(),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        nextPaymentDate: DateTime.parse(json['next_payment_date'] as String),
        monthlyPayment: (json['monthly_payment'] as num).toDouble(),
        status: LoanStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LoanStatus.pending,
        ),
        totalPayments: json['total_payments'] as int,
        completedPayments: json['completed_payments'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'principal_amount': principalAmount,
        'remaining_balance': remainingBalance,
        'interest_rate': interestRate,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'next_payment_date': nextPaymentDate.toIso8601String(),
        'monthly_payment': monthlyPayment,
        'status': status.name,
        'total_payments': totalPayments,
        'completed_payments': completedPayments,
      };

  // What fraction of payments are done (0.0 – 1.0).
  double get progressFraction =>
      totalPayments == 0 ? 0 : completedPayments / totalPayments;

  double get amountPaid => principalAmount - remainingBalance;
}
