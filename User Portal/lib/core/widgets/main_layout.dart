import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routing/route_names.dart';
import '../services/connectivity_provider.dart';
import '../services/sync_provider.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Executing Cloud Backup Synchronizer...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await ref.read(syncServiceProvider).syncOfflineBills('tenant_shop_01');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: result.successCount > 0 ? AppColors.success : AppColors.info,
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close Register Shift', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to close this POS shift and log out? All pending data will be synced.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay Open', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close & Log Out'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role ?? UserRole.admin; // fallback

    // Automatically collapse for smaller screens
    final effectiveExpanded = isMobile ? false : _isExpanded;
    final sidebarWidth = effectiveExpanded ? 260.0 : 78.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // 🚀 1. Sidebar Left Pane
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: sidebarWidth,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header Logo Box
                  Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                          effectiveExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.point_of_sale_rounded,
                              color: Colors.white, size: 22),
                        ),
                        if (effectiveExpanded) ...[
                          const SizedBox(width: 12),
                          Text(
                            'RathTech POS',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Dynamic Sidebar Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin || userRole == UserRole.manager || userRole == UserRole.accountant)
                          _buildNavItem(
                            context,
                            label: 'Dashboard',
                            icon: Icons.grid_view_rounded,
                            route: RouteNames.dashboard,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin || userRole == UserRole.manager || userRole == UserRole.cashier)
                          _buildNavItem(
                            context,
                            label: 'New Billing',
                            icon: Icons.receipt_long_rounded,
                            route: RouteNames.billing,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin || userRole == UserRole.manager || userRole == UserRole.cashier)
                          _buildNavItem(
                            context,
                            label: 'Inventory Catalog',
                            icon: Icons.inventory_2_outlined,
                            route: RouteNames.inventory,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin || userRole == UserRole.manager || userRole == UserRole.accountant)
                          _buildNavItem(
                            context,
                            label: 'Sales & Invoices',
                            icon: Icons.analytics_outlined,
                            route: RouteNames.salesReports,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin || userRole == UserRole.manager)
                          _buildNavItem(
                            context,
                            label: 'Store CRM VIP',
                            icon: Icons.people_outline_rounded,
                            route: RouteNames.crm,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin || userRole == UserRole.cashier || userRole == UserRole.accountant)
                          _buildNavItem(
                            context,
                            label: 'Cash Float Drawer',
                            icon: Icons.account_balance_wallet_outlined,
                            route: RouteNames.cashDrawer,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin)
                          _buildNavItem(
                            context,
                            label: 'Team & Staff',
                            icon: Icons.admin_panel_settings_rounded,
                            route: RouteNames.staffManagement,
                            isExpanded: effectiveExpanded,
                          ),
                        if (userRole == UserRole.admin || userRole == UserRole.superAdmin)
                          _buildNavItem(
                            context,
                            label: 'Terminal Settings',
                            icon: Icons.tune_rounded,
                            route: RouteNames.settings,
                            isExpanded: effectiveExpanded,
                          ),
                      ],
                    ),
                  ),

                  // Collapse Action Toggle At the Bottom
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: _toggleSidebar,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark.withValues(alpha: 0.5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          effectiveExpanded
                              ? Icons.keyboard_arrow_left_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

          // 🖥️ 2. Main Core Canvas Section
          Expanded(
            child: Column(
              children: [
                // 🎩 Floating Top Bar
                _buildTopBar(context, isDark, isMobile),

                // 📄 The Nested Active Page Screen
                Expanded(
                  child: Container(
                    color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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

  Widget _buildTopBar(BuildContext context, bool isDark, bool isMobile) {
    final isOnline = ref.watch(connectivityServiceProvider);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Search / Title
          Row(
            children: [
              if (isMobile) ...[
                Icon(Icons.point_of_sale_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
              ],
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Main Store Branch',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Terminal #01 • Active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right Top-bar Actions (Sync status, notifications, logout)
          Row(
            children: [
              // Dynamic Real-time Status Sync Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isOnline ? () => _handleSync(context, ref) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOnline
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          size: 15,
                          color: isOnline ? AppColors.success : AppColors.warning,
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Live Cloud Sync' : 'Offline Mode',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isOnline ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Notifications Bell icon
              IconButton(
                onPressed: () {},
                icon: Badge(
                  backgroundColor: AppColors.error,
                  alignment: Alignment.topRight,
                  child: Icon(Icons.notifications_outlined, color: Colors.grey.shade600, size: 22),
                ),
                tooltip: 'System Alerts',
              ),
              
              const SizedBox(width: 8),
              const VerticalDivider(indent: 24, endIndent: 24, width: 1),
              const SizedBox(width: 8),

              // Profile Avatar Widget with Dropdown triggers
              PopupMenuButton<int>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (idx) {
                  if (idx == 1) {
                    context.go(RouteNames.settings);
                  } else if (idx == 2) {
                    _handleLogout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: const [
                        Icon(Icons.person_outline_rounded, size: 18),
                        SizedBox(width: 12),
                        Text('My Profile Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                        SizedBox(width: 12),
                        Text('Close POS Shift', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.indigo.shade50,
                  child: const Icon(Icons.face_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
    required bool isExpanded,
  }) {
    final isActive = widget.currentPath == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = AppColors.primary;
    final activeBgColor = activeColor.withValues(alpha: isDark ? 0.15 : 0.06);
    
    final textTheme = GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      color: isActive
          ? activeColor
          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : Colors.grey.shade500,
                size: 20,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    height: 6,
                    width: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
