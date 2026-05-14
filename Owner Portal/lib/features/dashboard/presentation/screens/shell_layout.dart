import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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
                // Top Command Bar
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

class _SidebarContent extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const _SidebarContent({
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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

          // Navigation Nodes
          _SidebarNode(
            title: 'Overview',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            isActive: currentRoute == RouteNames.dashboard,
            onTap: () => onNavigate(RouteNames.dashboard),
          ),
          _SidebarNode(
            title: 'Active Tenants',
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            isActive: currentRoute == RouteNames.tenants,
            onTap: () => onNavigate(RouteNames.tenants),
          ),
          _SidebarNode(
            title: 'Subscription Plans',
            icon: Icons.credit_card_outlined,
            activeIcon: Icons.credit_card,
            isActive: currentRoute == RouteNames.plans,
            onTap: () => onNavigate(RouteNames.plans),
          ),
          _SidebarNode(
            title: 'Device Auditing',
            icon: Icons.devices_other_outlined,
            activeIcon: Icons.devices_other,
            isActive: currentRoute == RouteNames.devices,
            onTap: () => onNavigate(RouteNames.devices),
          ),
          
          const Spacer(),

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
            color: isActive ? selectedColor.withOpacity(0.1) : Colors.transparent,
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

class _TopBar extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onMenuPressed;

  const _TopBar({required this.isDesktop, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
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

          // Right Side Controls (Notifications & Profile Avatar)
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      'RA',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RathTech Admin',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Super Operator',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
