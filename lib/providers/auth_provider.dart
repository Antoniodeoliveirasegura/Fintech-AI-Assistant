import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/mock_api_service.dart';
import '../services/secure_token_store.dart';

// authProvider — global source of truth for "is the user signed in".
//
// This provider is special because the router watches it: when
// `state.user` flips from null to non-null, GoRouter's redirect callback
// re-runs and pushes the user to /dashboard. Logout is the same path in
// reverse. See lib/router/app_router.dart for the bridge.
//
// TODO(session): when wired to a real backend, also handle 401 responses
//   centrally (in ApiClient) by calling `logout()` here.

const _mockAuthToken = 'mock-session-token';

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => FlutterSecureTokenStore(),
);

// AuthState holds the entire auth slice — user, loading, and error are bundled
// so widgets reading the state get a consistent snapshot in a single rebuild.
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isRestoring;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isRestoring = true,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isRestoring,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        isRestoring: isRestoring ?? this.isRestoring,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required MockApiService apiService,
    required SecureTokenStore tokenStore,
  })  : _apiService = apiService,
        _tokenStore = tokenStore,
        super(const AuthState()) {
    restoreSession();
  }

  final MockApiService _apiService;
  final SecureTokenStore _tokenStore;
  int _sessionVersion = 0;

  Future<void> restoreSession() async {
    final restoreVersion = _sessionVersion;

    try {
      final token = await _tokenStore.readToken();
      if (restoreVersion != _sessionVersion) return;

      if (token == null) {
        state = const AuthState(isRestoring: false);
        return;
      }

      final user = await _apiService.getCurrentUser();
      if (restoreVersion != _sessionVersion) return;
      state = AuthState(user: user, isRestoring: false);
    } on Exception catch (e) {
      if (restoreVersion != _sessionVersion) return;
      await _tokenStore.deleteToken();
      state = AuthState(
        isRestoring: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> login(String email, String password) async {
    if (state.isLoading) return;
    _sessionVersion++;
    state = state.copyWith(
      isLoading: true,
      isRestoring: false,
      clearError: true,
    );

    try {
      final user = await _apiService.login(email, password);
      await _tokenStore.writeToken(_mockAuthToken);
      state = AuthState(user: user, isRestoring: false);
    } on Exception catch (e) {
      state = AuthState(
        isRestoring: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    _sessionVersion++;
    // Real implementation note: clear secure storage + cancel any in-flight
    // requests + invalidate dependent providers (loanProvider, paymentsProvider,
    // chatProvider) so the next session starts clean.
    await _tokenStore.deleteToken();
    state = const AuthState(isRestoring: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    apiService: MockApiService(),
    tokenStore: ref.watch(secureTokenStoreProvider),
  ),
);
