import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ShellLayout extends ConsumerStatefulWidget {
  final Widget child;
  const ShellLayout({super.key, required this.child});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateTo(String routeName) {
    context.go(routeName);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to terminate the active admin session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          )
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      key: _scaffoldKey,
      // Active Drawer for smaller screens
      drawer: !isDesktop
          ? Drawer(
              child: _SidebarContent(
                currentRoute: currentRoute,
                onNavigate: _navigateTo,
                onLogout: _handleLogout,
              ),
            )
          : null,
      body: Row(
        children: [
          // Persistent Left Sidebar on Desktop
          if (isDesktop)
            SizedBox(
              width: 260,
              child: _SidebarContent(
                currentRoute: currentRoute,
                onNavigate: _navigateTo,
                onLogout: _handleLogout,
              ),
            ),

          // Vertical Split line
          if (isDesktop)
            Container(
              width: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF374151)
                  : Colors.grey.shade200,
            ),

          // Right Main Content Port
          Expanded(
            child: Column(
              children: [
                // Top Command Bar (Interactive role switcher)
                _TopBar(
                  isDesktop: isDesktop,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                
                // Main Feature Area Viewport
                Expanded(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.backgroundDark
                        : Colors.grey.shade50,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const _SidebarContent({
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRole = ref.watch(simulatedRoleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check dynamic permission set
    bool hasPermission(AdminPermission permission) => activeRole.permissions.contains(permission);

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'RathTech Hub',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Menu Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'PLATFORM CONTROL',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Nodes (Enforces screen permissions based on AdminPermission enum)
          _SidebarNode(
            title: 'Overview',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            isActive: currentRoute == RouteNames.dashboard,
            onTap: () => onNavigate(RouteNames.dashboard),
          ),
          
          if (hasPermission(AdminPermission.manageTenants))
            _SidebarNode(
              title: 'Active Tenants',
              icon: Icons.groups_outlined,
              activeIcon: Icons.groups,
              isActive: currentRoute == RouteNames.tenants,
              onTap: () => onNavigate(RouteNames.tenants),
            ),
            
          if (hasPermission(AdminPermission.managePlans))
            _SidebarNode(
              title: 'Subscription Plans',
              icon: Icons.credit_card_outlined,
              activeIcon: Icons.credit_card,
              isActive: currentRoute == RouteNames.plans,
              onTap: () => onNavigate(RouteNames.plans),
            ),
            
          if (hasPermission(AdminPermission.manageDevices))
            _SidebarNode(
              title: 'Device Auditing',
              icon: Icons.devices_other_outlined,
              activeIcon: Icons.devices_other,
              isActive: currentRoute == RouteNames.devices,
              onTap: () => onNavigate(RouteNames.devices),
            ),
          
          const Spacer(),

          // Simulated permission details card
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMULATION CONSOLE',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Role: ${activeRole.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').toUpperCase()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allows ${activeRole.permissions.length} of 7 permissions.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
          const SizedBox(height: 8),

          // Logout Block
          _SidebarNode(
            title: 'Sign Out Session',
            icon: Icons.logout_rounded,
            activeIcon: Icons.logout_rounded,
            isActive: false,
            colorOverride: AppColors.error,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SidebarNode extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? colorOverride;

  const _SidebarNode({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final Color selectedColor = AppColors.primary;
    final Color finalColor = colorOverride ?? (isActive ? selectedColor : defaultColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isActive ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(isActive ? activeIcon : icon, color: finalColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: finalColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final bool isDesktop;
  final VoidCallback onMenuPressed;

  const _TopBar({required this.isDesktop, required this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRole = ref.watch(simulatedRoleProvider);

    // Get formatted role title
    String getRoleTitle(UserRole role) {
      switch (role) {
        case UserRole.superOwner: return 'Super Owner';
        case UserRole.admin: return 'Administrator';
        case UserRole.supportStaff: return 'Support Staff';
        case UserRole.financeManager: return 'Finance Manager';
        case UserRole.salesManager: return 'Sales Manager';
        case UserRole.technicalTeam: return 'Technical Team';
        case UserRole.readOnlyAnalyst: return 'ReadOnly Analyst';
      }
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mobile Drawer Button or Search Bar
          if (!isDesktop)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
            )
          else
            // Desktop Quick Search Placeholder
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1F2937)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Search shops, plans, or docs...',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

          // Right Side Controls (Notifications & Dynamic Simulated Role Selection Dropdown)
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 16),
              PopupMenuButton<UserRole>(
                onSelected: (role) {
                  ref.read(simulatedRoleProvider.notifier).state = role;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔒 Switched Simulation Mode: ${getRoleTitle(role)} Access Active.'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                offset: const Offset(0, 48),
                itemBuilder: (context) {
                  return UserRole.values.map((role) {
                    final isSelected = role == activeRole;
                    return PopupMenuItem<UserRole>(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            getRoleTitle(role),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          activeRole.name[0].toUpperCase() + (activeRole.name.length > 1 ? activeRole.name[1].toUpperCase() : ''),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RathTech Admin',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                            ],
                          ),
                          Text(
                            getRoleTitle(activeRole),
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
