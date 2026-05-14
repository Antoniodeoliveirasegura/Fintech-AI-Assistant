import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../providers/payments_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_loading_widget.dart';
import '../widgets/app_error_widget.dart';
import '../widgets/payment_list_item.dart';
import '../widgets/status_badge.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider);
    final filter = ref.watch(paymentFilterProvider);
    final filteredAsync = ref.watch(filteredPaymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: paymentsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Loading payments...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(paymentsProvider),
        ),
        data: (_) => Column(
          children: [
            // ── Filter chips bar ──────────────────────────────────────
            _FilterBar(selected: filter),
            const Divider(height: 1),

            // ── Payment list ──────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                loading: () => const AppLoadingWidget(),
                error: (e, _) => AppErrorWidget(message: e.toString()),
                data: (payments) {
                  if (payments.isEmpty) {
                    return _EmptyState(filter: filter);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(paymentsProvider);
                      try {
                        await ref.read(paymentsProvider.future);
                      } catch (_) {}
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: payments.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: AppSpacing.md + 44 + AppSpacing.md,
                      ),
                      itemBuilder: (context, i) => PaymentListItem(
                        payment: payments[i],
                        onTap: () =>
                            _showDetail(context, payments[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Payment payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PaymentDetailSheet(payment: payment),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips
// ---------------------------------------------------------------------------

class _FilterBar extends ConsumerWidget {
  final PaymentFilter selected;

  const _FilterBar({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        itemCount: PaymentFilter.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final filter = PaymentFilter.values[i];
          final isSelected = filter == selected;
          return FilterChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(paymentFilterProvider.notifier).state = filter,
            selectedColor: AppColors.primary.withValues(alpha: 0.12),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final PaymentFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final String message;
    final IconData icon;

    switch (filter) {
      case PaymentFilter.paid:
        message = 'No paid payments yet.';
        icon = Icons.check_circle_outline_rounded;
      case PaymentFilter.upcoming:
        message = 'No upcoming payments.';
        icon = Icons.schedule_rounded;
      case PaymentFilter.late:
        message = 'No late payments. Great job!';
        icon = Icons.thumb_up_outlined;
      case PaymentFilter.all:
        message = 'No payments found.';
        icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment detail bottom sheet
// ---------------------------------------------------------------------------

class _PaymentDetailSheet extends StatelessWidget {
  final Payment payment;

  const _PaymentDetailSheet({required this.payment});

  static final _currency = NumberFormat.currency(symbol: '\$');
  static final _date = DateFormat('MMMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              StatusBadge.forPayment(payment.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Amount
          _DetailRow(
            label: 'Amount',
            value: _currency.format(payment.amount),
            valueStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: AppSpacing.lg),

          _DetailRow(label: 'Payment ID', value: payment.id),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Loan ID', value: payment.loanId),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Due Date', value: _date.format(payment.dueDate)),
          if (payment.paidDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              label: 'Paid On',
              value: _date.format(payment.paidDate!),
            ),
          ],
          if (payment.status == PaymentStatus.late) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'This payment is overdue. Contact support to avoid credit impact.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle ??
                Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
