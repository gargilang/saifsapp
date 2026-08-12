import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/sync_badge.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = ['/', '/customers', '/reports', '/budget', '/settings'];

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/customers')) return 1;
    if (loc.startsWith('/reports')) return 2;
    if (loc.startsWith('/budget')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const BrandLogo(size: 22),
          const SizedBox(width: 8),
          Text(kBrandShortName),
        ]),
        actions: const [SyncBadge(), SizedBox(width: 8)],
      ),
      body: Column(children: [const OfflineBanner(), Expanded(child: child)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexOf(context),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Customer'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Laporan'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Anggaran'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Pengaturan'),
        ],
      ),
    );
  }
}
