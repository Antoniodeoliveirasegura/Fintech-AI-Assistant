import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/chat_provider.dart';
import '../router/app_router.dart';
import '../utils/app_theme.dart';
import '../widgets/fintech_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_loading_widget.dart';
import '../widgets/app_error_widget.dart';
import '../widgets/payment_list_item.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final loanAsync = ref.watch(loanProvider);
    final paymentsAsync = ref.watch(paymentsProvider);

    // Router guarantees user is non-null when on this screen, but we still
    // fall back defensively if a logout race lands here mid-frame.
    final greeting = user != null ? 'Hi, ${user.firstName}' : 'Dashboard';

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        actions: [
          _ProfileMenu(user: user),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loanProvider);
          ref.invalidate(paymentsProvider);
          try {
            await ref.read(loanProvider.future);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            // ── Loan balance hero card ──────────────────────────────────
            loanAsync.when(
              data: (loan) => _LoanHeroCard(loan: loan),
              loading: () => const AppLoadingWidget(
                message: 'Loading your account...',
              ),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(loanProvider),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Next payment ────────────────────────────────────────────
            loanAsync.maybeWhen(
              data: (loan) => _NextPaymentCard(loan: loan),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── AI Assistant banner ─────────────────────────────────────
            _AssistantBanner(
              onTap: () => context.go(AppRoutes.assistant),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Recent payments ─────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Recent Payments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.payments),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            paymentsAsync.when(
              data: (payments) {
                final recent = payments
                    .where((p) => p.status == PaymentStatus.paid)
                    .take(3)
                    .toList();
                if (recent.isEmpty) {
                  return FintechCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No payments made yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }
                return FintechCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: recent
                        .map((p) => PaymentListItem(
                              payment: p,
                              onTap: () => context.go(AppRoutes.payments),
                            ))
                        .toList(),
                  ),
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(paymentsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loan hero card — gradient background with balance, progress, status.
// ---------------------------------------------------------------------------

class _LoanHeroCard extends StatelessWidget {
  final Loan loan;

  const _LoanHeroCard({required this.loan});

  static final _currency = NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Loan Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge.forLoan(loan.status, onDark: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currency.format(loan.remainingBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${_currency.format(loan.principalAmount)} original loan  ·  ${loan.interestRate}% APR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progress bar — animates from 0 to target on mount.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: loan.progressFraction),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loan.completedPayments} of ${loan.totalPayments} payments',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                '${(loan.progressFraction * 100).toStringAsFixed(0)}% complete',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next payment card
// ---------------------------------------------------------------------------

class _NextPaymentCard extends StatelessWidget {
  final Loan loan;

  const _NextPaymentCard({required this.loan});

  static final _currency = NumberFormat.currency(symbol: '\$');
  static final _date = DateFormat('MMMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return FintechCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Payment',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currency.format(loan.monthlyPayment),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  _date.format(loan.nextPaymentDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _PayNowChip(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Assistant promotional banner
// ---------------------------------------------------------------------------

class _AssistantBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AssistantBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FintechCard(
      backgroundColor: const Color(0xFFF0FDF4),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask AI Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get instant answers about your loan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Pay now" chip — tappable demo placeholder. Real flow would open a sheet.
// ---------------------------------------------------------------------------

class _PayNowChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Demo: payment flow is not wired up.'),
                duration: Duration(seconds: 2),
              ),
            );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: const Text(
            'Pay now',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile / logout menu in the AppBar
// ---------------------------------------------------------------------------

class _ProfileMenu extends ConsumerWidget {
  final User? user;

  const _ProfileMenu({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = (user?.firstName.isNotEmpty ?? false)
        ? user!.firstName.substring(0, 1).toUpperCase()
        : '?';

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      tooltip: 'Account',
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.name ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          // Clear chat history before logout so the next session starts clean.
          ref.invalidate(chatProvider);
          await ref.read(authProvider.notifier).logout();
        }
      },
    );
  }
}
