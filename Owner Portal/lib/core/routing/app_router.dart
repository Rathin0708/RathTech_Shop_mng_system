import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/shell_layout.dart';
import 'route_names.dart';

import '../../features/tenants/presentation/screens/tenants_list_screen.dart';

import '../../features/plans/presentation/screens/plans_screen.dart';
import '../../features/devices/presentation/screens/devices_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: true,
    routes: [
      // Auth Node (Standalone page without Sidebar)
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Core Application Shell (Wrapped inside ShellLayout)
      ShellRoute(
        builder: (context, state, child) {
          return ShellLayout(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.tenants,
            name: 'tenants',
            builder: (context, state) => const TenantsListScreen(),
          ),
          GoRoute(
            path: RouteNames.plans,
            name: 'plans',
            builder: (context, state) => const PlansScreen(),
          ),
          GoRoute(
            path: RouteNames.devices,
            name: 'devices',
            builder: (context, state) => const DevicesScreen(),
          ),
        ],
      ),
    ],
  );
});

