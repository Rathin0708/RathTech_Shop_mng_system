import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import 'route_names.dart';

import '../../features/billing/presentation/screens/billing_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/sales/presentation/screens/sales_history_screen.dart';
import '../../features/cash/presentation/screens/cash_drawer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.billing,
        name: 'billing',
        builder: (context, state) => const BillingScreen(),
      ),
      GoRoute(
        path: RouteNames.inventory,
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.salesReports,
        name: 'sales_reports',
        builder: (context, state) => const SalesHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.cashDrawer,
        name: 'cash_drawer',
        builder: (context, state) => const CashDrawerScreen(),
      ),
    ],
  );
});

