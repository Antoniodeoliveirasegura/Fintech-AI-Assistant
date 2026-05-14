import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/mock_api_service.dart';

// authProvider — global source of truth for "is the user signed in".
//
// This provider is special because the router watches it: when
// `state.user` flips from null to non-null, GoRouter's redirect callback
// re-runs and pushes the user to /dashboard. Logout is the same path in
// reverse. See lib/router/app_router.dart for the bridge.
//
// TODO(real-auth): persist the auth token in flutter_secure_storage on login
//   success and clear it on logout. Add a `restoreSession()` method that
//   `main()` awaits before runApp() so returning users skip the login screen.
// TODO(session): when wired to a real backend, also handle 401 responses
//   centrally (in ApiClient) by calling `logout()` here.

// AuthState holds the entire auth slice — user, loading, and error are bundled
// so widgets reading the state get a consistent snapshot in a single rebuild.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await MockApiService().login(email, password);
      state = AuthState(user: user);
      // Real implementation note: persist token via flutter_secure_storage
      // here, and hydrate it on app start in a separate `restoreSession()`
      // method that's awaited inside main() before runApp().
    } on Exception catch (e) {
      state = AuthState(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void logout() {
    // Real implementation note: clear secure storage + cancel any in-flight
    // requests + invalidate dependent providers (loanProvider, paymentsProvider,
    // chatProvider) so the next session starts clean.
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
