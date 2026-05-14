import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/mock_api_service.dart';

enum PaymentFilter { all, paid, upcoming, late }

extension PaymentFilterLabel on PaymentFilter {
  String get label {
    switch (this) {
      case PaymentFilter.all:
        return 'All';
      case PaymentFilter.paid:
        return 'Paid';
      case PaymentFilter.upcoming:
        return 'Upcoming';
      case PaymentFilter.late:
        return 'Late';
    }
  }
}

// paymentsProvider — async fetch of all payments for the active loan.
// TODO(django-backend): wire to GET /api/v1/loans/{id}/payments.
final paymentsProvider = FutureProvider<List<Payment>>((ref) {
  return MockApiService().getPayments();
});

// paymentFilterProvider — pure UI state for the chip row (no async work).
// `StateProvider` is the lightweight choice for "one value, mutated freely".
final paymentFilterProvider = StateProvider<PaymentFilter>(
  (ref) => PaymentFilter.all,
);

// filteredPaymentsProvider — derives the visible list from raw payments +
// the active filter. This pattern (a `Provider` that watches other providers)
// is how Riverpod handles "computed" state without re-fetching from the API.
final filteredPaymentsProvider = Provider<AsyncValue<List<Payment>>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  final filter = ref.watch(paymentFilterProvider);

  return paymentsAsync.whenData((payments) {
    switch (filter) {
      case PaymentFilter.all:
        return payments;
      case PaymentFilter.paid:
        return payments.where((p) => p.status == PaymentStatus.paid).toList();
      case PaymentFilter.upcoming:
        return payments
            .where((p) => p.status == PaymentStatus.upcoming)
            .toList();
      case PaymentFilter.late:
        return payments.where((p) => p.status == PaymentStatus.late).toList();
    }
  });
});
