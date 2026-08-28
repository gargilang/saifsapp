import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_providers.dart';
import 'core/brand.dart';
import 'core/pin_lock.dart';
import 'core/theme.dart';
import 'core/theme_mode.dart';
import 'features/auth/login_page.dart';
import 'features/auth/pin_lock_page.dart';
import 'features/budget/budget_page.dart';
import 'features/customers/customer_detail_page.dart';
import 'features/customers/customers_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/reports/reports_page.dart';
import 'features/settings/settings_page.dart';
import 'features/shell/app_shell.dart';

Widget _selectablePage(Widget child) => SelectionArea(child: child);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authStateProvider, (_, _) => refresh.value++);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => _selectablePage(const LoginPage()),
      ),
      ShellRoute(
        builder: (_, _, child) => _selectablePage(AppShell(child: child)),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/customers', builder: (_, _) => const CustomersPage()),
          GoRoute(
              path: '/customers/:id',
              builder: (_, s) =>
                  CustomerDetailPage(customerId: s.pathParameters['id']!)),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsPage()),
          GoRoute(path: '/budget', builder: (_, _) => const BudgetPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
        ],
      ),
    ],
  );
});

class SandiApp extends ConsumerWidget {
  const SandiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinLockProvider);
    if (pin.enabled && pin.locked) {
      return MaterialApp(
        title: kBrandShortName,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ref.watch(themeModeProvider),
        home: _selectablePage(const PinLockPage()),
      );
    }
    return MaterialApp.router(
      title: kBrandShortName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
    );
  }
}
