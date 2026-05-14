import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/mock_api_service.dart';

final userProvider = FutureProvider<User>((ref) {
  return MockApiService().getCurrentUser();
});
