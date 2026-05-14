import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../services/mock_api_service.dart';

// loanProvider — fetches the user's active loan once and caches the result.
// Widgets that `ref.watch(loanProvider)` get an `AsyncValue<Loan>`, which is
// either loading, error, or data — no manual isLoading flags needed.
//
// To re-fetch (e.g. pull-to-refresh): `ref.invalidate(loanProvider)`.
//
// TODO(django-backend): once RemoteApiService exists, swap MockApiService()
//   here, or inject the service via an `apiServiceProvider`.
final loanProvider = FutureProvider<Loan>((ref) {
  return MockApiService().getLoan();
});
