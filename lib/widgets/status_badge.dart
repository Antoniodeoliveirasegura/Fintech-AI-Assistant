import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool onDark; // true when placed on a dark/gradient background

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.onDark = false,
  });

  factory StatusBadge.forLoan(LoanStatus status, {bool onDark = false}) {
    final Color c;
    switch (status) {
      case LoanStatus.active:
        c = AppColors.loanActive;
      case LoanStatus.paid:
        c = AppColors.loanPaid;
      case LoanStatus.defaulted:
        c = AppColors.loanDefaulted;
      case LoanStatus.pending:
        c = AppColors.loanPending;
    }
    return StatusBadge(label: status.label, color: c, onDark: onDark);
  }

  factory StatusBadge.forPayment(PaymentStatus status) {
    final Color c;
    switch (status) {
      case PaymentStatus.paid:
        c = AppColors.paymentPaid;
      case PaymentStatus.upcoming:
        c = AppColors.paymentUpcoming;
      case PaymentStatus.late:
        c = AppColors.paymentLate;
    }
    return StatusBadge(label: status.label, color: c);
  }

  @override
  Widget build(BuildContext context) {
    if (onDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
