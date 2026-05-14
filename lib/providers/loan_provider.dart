import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../services/mock_api_service.dart';

final loanProvider = FutureProvider<Loan>((ref) {
  return MockApiService().getLoan();
});
