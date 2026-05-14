import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/assistant_screen.dart';

// Route path constants — import these anywhere instead of hard-coding strings.
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const payments = '/payments';
  static const assistant = '/assistant';

  static const loginName = 'login';
  static const dashboardName = 'dashboard';
  static const paymentsName = 'payments';
  static const assistantName = 'assistant';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Bridge: Riverpod auth state -> Listenable for GoRouter.
  // Bumping `.value` triggers notifyListeners(), which makes GoRouter re-run
  // its redirect callback. We dispose it with the provider's lifecycle.
  final authRefresh = ValueNotifier<int>(0);
  ref.onDispose(authRefresh.dispose);
  ref.listen<AuthState>(authProvider, (prev, next) => authRefresh.value++);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isRestoring) return null;

      final isAuth = auth.isAuthenticated;
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      if (!isAuth) return isOnLogin ? null : AppRoutes.login;
      if (isOnLogin) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoutes.loginName,
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // ShellRoute wraps the authenticated tabs in the bottom-nav shell.
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            name: AppRoutes.dashboardName,
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            name: AppRoutes.paymentsName,
            path: AppRoutes.payments,
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            name: AppRoutes.assistantName,
            path: AppRoutes.assistant,
            builder: (context, state) => const AssistantScreen(),
          ),
        ],
      ),
    ],
  );
});
