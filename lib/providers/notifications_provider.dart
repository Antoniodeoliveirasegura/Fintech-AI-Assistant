import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_notification.dart';
import '../services/mock_api_service.dart';

// StreamProvider is Riverpod's fit for live data: widgets still receive an
// AsyncValue, but the value can update repeatedly over time.
final accountNotificationsProvider = StreamProvider<List<AccountNotification>>((
  ref,
) {
  return MockApiService().watchAccountNotifications();
});
