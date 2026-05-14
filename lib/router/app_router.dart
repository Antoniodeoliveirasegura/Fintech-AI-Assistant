import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // ShellRoute wraps dashboard/payments/assistant in the bottom nav shell.
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.payments,
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.assistant,
            builder: (context, state) => const AssistantScreen(),
          ),
        ],
      ),
    ],
  );
});
