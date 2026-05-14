import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    // ProviderScope is the Riverpod root — all providers live inside it.
    const ProviderScope(
      child: FintechApp(),
    ),
  );
}

class FintechApp extends ConsumerWidget {
  const FintechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Fintech AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
