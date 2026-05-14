import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../utils/app_theme.dart';
import 'status_badge.dart';

class PaymentListItem extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;

  const PaymentListItem({super.key, required this.payment, this.onTap});

  static final _currency = NumberFormat.currency(symbol: '\$');
  static final _date = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            _StatusIcon(status: payment.status),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currency.format(payment.amount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${_date.format(payment.dueDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            StatusBadge.forPayment(payment.status),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final PaymentStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    switch (status) {
      case PaymentStatus.paid:
        color = AppColors.paymentPaid;
        icon = Icons.check_circle_outline_rounded;
      case PaymentStatus.upcoming:
        color = AppColors.paymentUpcoming;
        icon = Icons.schedule_rounded;
      case PaymentStatus.late:
        color = AppColors.paymentLate;
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
