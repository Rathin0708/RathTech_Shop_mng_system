import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/models/tenant_model.dart';
import '../../../devices/presentation/providers/device_providers.dart';
import '../../../tenants/presentation/providers/tenant_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch live tenant, device and plan state arrays
    final tenants = ref.watch(tenantsListProvider);
    final devices = ref.watch(devicesListProvider);

    // 2. Compute dynamic operational metrics
    final int activeTenants = tenants.where((t) => t.status == TenantStatus.active || t.status == TenantStatus.trial).length;
    final int activeSessions = devices.where((d) => d.status == 'Online').length;
    final int failedSyncs = 4; // Simulated ledger sync queues pending resolution

    // Compute dynamic MRR (Monthly Recurring Revenue) based on each active tenant's pricing structure
    double dynamicMRR = 0;
    for (final tenant in tenants) {
      if (tenant.status == TenantStatus.active) {
        final planId = tenant.currentPlanId.toLowerCase();
        if (planId.contains('enterprise')) {
          dynamicMRR += 5999;
        } else if (planId.contains('pro')) {
          dynamicMRR += 2499;
        } else {
          dynamicMRR += 999; // Standard retail starter tier rate
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Welcome Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SaaS Overview',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time subscription metrics and platform status.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.tenants),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add New Tenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
          const SizedBox(height: 40),

          // 2. Analytics Cards Grid (Dynamically wired to live providers)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;
              final isMedium = constraints.maxWidth > 600 && constraints.maxWidth <= 1000;
              
              int crossAxisCount = 4;
              if (isMedium) crossAxisCount = 2;
              if (!isWide && !isMedium) crossAxisCount = 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.8,
                children: [
                  _AnalyticsCard(
                    title: 'Total Revenue (MRR)',
                    value: '₹${dynamicMRR.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    percentage: '+14.2%',
                    isPositive: true,
                    icon: Icons.monetization_on_outlined,
                    iconColor: const Color(0xFF10B981),
                  ),
                  _AnalyticsCard(
                    title: 'Active Tenants',
                    value: activeTenants.toString(),
                    percentage: '+8.4%',
                    isPositive: true,
                    icon: Icons.store_mall_directory_outlined,
                    iconColor: AppColors.primary,
                  ),
                  _AnalyticsCard(
                    title: 'Live Active Sessions',
                    value: activeSessions.toString(),
                    percentage: '+21%',
                    isPositive: true,
                    icon: Icons.devices_other_rounded,
                    iconColor: AppColors.secondary,
                  ),
                  _AnalyticsCard(
                    title: 'Failed Sync Events',
                    value: failedSyncs.toString(),
                    percentage: '-34%',
                    isPositive: true,
                    icon: Icons.sync_problem_rounded,
                    iconColor: AppColors.error,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // 3. Chart and Logs Flex Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Placeholder (70% width)
                  Expanded(
                    flex: isWide ? 7 : 0,
                    child: Container(
                      height: 380,
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
                            'Weekly Revenue Performance',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ChartBar(label: 'Mon', heightFactor: 0.4),
                                _ChartBar(label: 'Tue', heightFactor: 0.6),
                                _ChartBar(label: 'Wed', heightFactor: 0.8),
                                _ChartBar(label: 'Thu', heightFactor: 0.55),
                                _ChartBar(label: 'Fri', heightFactor: 0.92),
                                _ChartBar(label: 'Sat', heightFactor: 0.75),
                                _ChartBar(label: 'Sun', heightFactor: 0.65),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 24),
                  if (!isWide) const SizedBox(height: 24),

                  // Recent Alerts Module (30% width)
                  Expanded(
                    flex: isWide ? 4 : 0,
                    child: Container(
                      height: 380,
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
                            'Recent Support Queries',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _AlertItem(
                            title: 'A2B Sweets - Sync Issue',
                            subtitle: 'Inventory count mismatch on lane 3',
                            time: '12m ago',
                            tagColor: Colors.orange,
                          ),
                          const _AlertItem(
                            title: 'Apollo Pharmacy - License expired',
                            subtitle: 'Plan Renewal via Razorpay failed',
                            time: '45m ago',
                            tagColor: Colors.red,
                          ),
                          const _AlertItem(
                            title: 'Saravana Stores - Add Branch',
                            subtitle: 'Requested quote expansion to 4 lanes',
                            time: '2h ago',
                            tagColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentage;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                percentage,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'from last month',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final double heightFactor;

  const _ChartBar({required this.label, required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color tagColor;

  const _AlertItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            width: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tagColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
          )
        ],
      ),
    );
  }
}
