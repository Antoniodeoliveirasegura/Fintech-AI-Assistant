// Payment — one scheduled or completed payment against a loan.
// `paidDate` is nullable because upcoming and late payments haven't been paid.
enum PaymentStatus { paid, upcoming, late }

extension PaymentStatusLabel on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.upcoming:
        return 'Upcoming';
      case PaymentStatus.late:
        return 'Late';
    }
  }
}

class Payment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate; // null if not yet paid
  final PaymentStatus status;

  const Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.dueDate,
    required this.paidDate,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        loanId: json['loan_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['due_date'] as String),
        paidDate: json['paid_date'] != null
            ? DateTime.parse(json['paid_date'] as String)
            : null,
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PaymentStatus.upcoming,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'loan_id': loanId,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        'paid_date': paidDate?.toIso8601String(),
        'status': status.name,
      };
}
