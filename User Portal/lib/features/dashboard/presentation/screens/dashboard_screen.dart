import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/sync_provider.dart';
import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../billing/presentation/providers/parked_carts_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    // Update local POS clock every second
    _timeStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  Future<void> _handleLogout() async {
    final logoutConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Register Shift'),
        content: const Text('Are you sure you want to close this POS shift and log out? All pending data will be synced.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay Open')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Shift & Log Out'),
          )
        ],
      ),
    );

    if (logoutConfirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkedCarts = ref.watch(parkedCartsProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _POSHeader(onLogoutPressed: _handleLogout),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Main Workspace Grid (70%)
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register Operations',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.3,
                      children: [
                        _QuickActionTile(
                          title: 'New Checkout Bill',
                          subtitle: 'Scan and collect payment',
                          icon: Icons.point_of_sale_rounded,
                          color: AppColors.primary,
                          onTap: () => context.go(RouteNames.billing),
                        ),
                        _QuickActionTile(
                          title: 'Inventory Lookup',
                          subtitle: 'Browse stocks & pricing',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.accent,
                          onTap: () => context.go(RouteNames.inventory),
                        ),
                        _QuickActionTile(
                          title: 'Sales Reports',
                          subtitle: 'Review active shift ledger',
                          icon: Icons.assessment_rounded,
                          color: AppColors.secondary,
                          onTap: () => context.go(RouteNames.salesReports),
                        ),
                        _QuickActionTile(
                          title: 'Hold / Draft Bills',
                          subtitle: '${parkedCarts.length} orders parked',
                          icon: Icons.pause_circle_filled_rounded,
                          color: Colors.amber.shade700,
                          badgeCount: parkedCarts.length,
                          onTap: () => context.go(RouteNames.billing),
                        ),
                        _QuickActionTile(
                          title: 'Cash Management',
                          subtitle: 'Pay in / Pay out float',
                          icon: Icons.money_rounded,
                          color: Colors.green,
                          onTap: () => context.go(RouteNames.cashDrawer),
                        ),
                        _QuickActionTile(
                          title: 'Customer Base',
                          subtitle: 'Manage loyalty profiles',
                          icon: Icons.people_alt_rounded,
                          color: Colors.indigo,
                          onTap: () {},
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 24),

            // 2. Side Summary Shift Stats (30%)
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Live Shift Clock Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.watch_later_rounded, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ACTIVE SHIFT TIME',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<DateTime>(
                          stream: _timeStream,
                          builder: (context, snapshot) {
                            final now = snapshot.data ?? DateTime.now();
                            return Text(
                              DateFormat('HH:mm:ss').format(now),
                              style: GoogleFonts.outfit(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shift Summary Drawer
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF374151)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Ledger Summary',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          const _LedgerRow(label: 'Opening Cash Float', value: '₹5,000.00'),
                          const _LedgerRow(label: 'Cash Collections', value: '₹12,450.00'),
                          const _LedgerRow(label: 'Card / UPI Payments', value: '₹24,800.00'),
                          const Divider(height: 32),
                          const _LedgerRow(
                            label: 'Total Register Net',
                            value: '₹42,250.00',
                            isBold: true,
                            valueColor: AppColors.success,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.print_rounded, size: 20),
                              label: const Text('Print Mini Report (X-Read)'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _POSHeader extends ConsumerWidget {
  final VoidCallback onLogoutPressed;
  const _POSHeader({required this.onLogoutPressed});

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(
        children: [
          SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Executing Cloud Backup Synchronizer...'),
        ],
      ), duration: Duration(seconds: 1)),
    );

    final result = await ref.read(syncServiceProvider).syncOfflineBills('tenant_shop_01');
    
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.successCount > 0 ? AppColors.success : AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RathTech Retail POS',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Terminal #01 • Main Store Branch',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                    )
                  ],
                ),
              ],
            ),
            
            // Right Section (Dynamic Sync Badge, Staff Profile, Power/Logout Button)
            Row(
              children: [
                // Offline/Online Sync Status Badge -> Dynamic Render
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isOnline ? () => _handleSync(context, ref) : null, // Disable click when offline
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isOnline ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            size: 16,
                            color: isOnline ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Online & Synced' : 'Offline (Local Mode)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOnline ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person_rounded, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                
                // Settings Gear Button
                IconButton(
                  onPressed: () => context.go(RouteNames.settings),
                  icon: Icon(Icons.settings_rounded, color: Colors.grey.shade600),
                  tooltip: 'Terminal Settings',
                ),
                const SizedBox(width: 4),
                
                // Power Logout Button
                IconButton(
                  onPressed: onLogoutPressed,
                  icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.error),
                  tooltip: 'Close Shift',
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF374151)
                  : Colors.grey.shade200,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 32, color: color),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  )
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _LedgerRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: isBold ? 15 : 13,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: isBold 
          ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
          : Colors.grey.shade600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(
            value,
            style: textStyle.copyWith(
              color: valueColor ?? (isBold ? textStyle.color : null),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
