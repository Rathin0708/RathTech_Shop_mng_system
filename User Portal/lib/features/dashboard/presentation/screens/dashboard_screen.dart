import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/shop_profile_provider.dart';
import '../../../../core/models/tenant_model.dart';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/widgets/premium_paywall_dialog.dart';
import '../../../billing/presentation/providers/parked_carts_provider.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../../../crm/presentation/providers/customer_providers.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/customer_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../sales/presentation/providers/sales_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parkedCarts = ref.watch(parkedCartsProvider);
    final shopProfile = ref.watch(shopProfileProvider);
    final onboarding = ref.watch(onboardingProvider);
    final subscription = ref.watch(subscriptionProvider);
    final products = ref.watch(productsListProvider);
    final customers = ref.watch(customersListProvider);
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    final salesHistoryAsync = ref.watch(salesHistoryProvider);

    // Calculate real dynamic Today's Net Sales
    final todayBills = salesHistoryAsync.value?.where((b) {
      final now = DateTime.now();
      return b.timestamp.year == now.year &&
             b.timestamp.month == now.month &&
             b.timestamp.day == now.day;
    }).toList() ?? [];

    final todaySales = todayBills.fold(0.0, (sum, b) => sum + b.netTotal);

    // Calculate Profit Margins based on products cost price vs selling price
    double profitMargins = 0.0;
    for (final bill in todayBills) {
      for (final item in bill.purchasedItems) {
        final prod = products.where((p) => p.id == item.productId).firstOrNull;
        if (prod != null) {
          profitMargins += (item.unitPrice - prod.costPrice) * item.quantity;
        } else {
          profitMargins += item.lineTotal * 0.20; // 20% fallback margin
        }
      }
    }

    // Calculate Pending Dues
    final totalPendingDues = customers.fold(0.0, (sum, c) => sum + c.pendingDues);

    // Calculate chart data hourly sales momentum based on actual today's sales
    final hourlySales = {
      '09 AM': 0.0,
      '11 AM': 0.0,
      '01 PM': 0.0,
      '03 PM': 0.0,
      '05 PM': 0.0,
      '07 PM': 0.0,
      '09 PM': 0.0,
    };

    for (final bill in todayBills) {
      final hour = bill.timestamp.hour;
      if (hour < 10) {
        hourlySales['09 AM'] = (hourlySales['09 AM'] ?? 0.0) + bill.netTotal;
      } else if (hour < 12) {
        hourlySales['11 AM'] = (hourlySales['11 AM'] ?? 0.0) + bill.netTotal;
      } else if (hour < 14) {
        hourlySales['01 PM'] = (hourlySales['01 PM'] ?? 0.0) + bill.netTotal;
      } else if (hour < 16) {
        hourlySales['03 PM'] = (hourlySales['03 PM'] ?? 0.0) + bill.netTotal;
      } else if (hour < 18) {
        hourlySales['05 PM'] = (hourlySales['05 PM'] ?? 0.0) + bill.netTotal;
      } else if (hour < 20) {
        hourlySales['07 PM'] = (hourlySales['07 PM'] ?? 0.0) + bill.netTotal;
      } else {
        hourlySales['09 PM'] = (hourlySales['09 PM'] ?? 0.0) + bill.netTotal;
      }
    }

    final chartData = hourlySales.entries.map((e) => _SalesData(e.key, e.value)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by MainLayout app background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📣 1. Smart Dashboard Welcome Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, ${currentUser?.name ?? 'Admin'} 👋',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          currentUser?.email != null
                              ? 'Connected: ${currentUser!.email} | Role: ${currentUser.role.name.toUpperCase()}'
                              : 'Here is your retail operations digest for today.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (subscription.isPremium) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'ELITE SaaS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          InkWell(
                            onTap: () => showPremiumPaywallDialog(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${subscription.trialDaysRemaining} Days Left in Trial (Upgrade)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Primary CTA (F12 New Bill Shortcut)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.go(RouteNames.billing),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Create New Bill (F12)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            if (!subscription.isPremium) ...[
              _buildTrialBanner(context, isDark),
              const SizedBox(height: 24),
            ],
            if (!onboarding.isDismissed && onboarding.progressPercentage < 1.0) ...[
              _buildOnboardingConsole(context, onboarding, isDark),
              const SizedBox(height: 24),
            ],
            if (shopProfile != ShopCategory.general) ...[
              _buildIndustryConsole(context, shopProfile, isDark),
              const SizedBox(height: 24),
            ],

            // 📊 2. Smart KPI Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1000
                    ? 4
                    : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.8,
                  ),
                  children: [
                    _buildKpiCard(
                      context,
                      title: 'Today\'s Net Sales',
                      value: '₹${NumberFormat('#,##,##0.00', 'en_IN').format(todaySales)}',
                      trend: todaySales > 0 ? '+100.0%' : '0.0%',
                      isPositive: todaySales >= 0,
                      icon: Icons.insights_rounded,
                      color: AppColors.primary,
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Profit Margins',
                      value: '₹${NumberFormat('#,##,##0.00', 'en_IN').format(profitMargins)}',
                      trend: profitMargins > 0 ? '+100.0%' : '0.0%',
                      isPositive: profitMargins >= 0,
                      icon: Icons.account_balance_rounded,
                      color: AppColors.success,
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Pending Dues',
                      value: '₹${NumberFormat('#,##,##0.00', 'en_IN').format(totalPendingDues)}',
                      trend: totalPendingDues > 0 ? 'Active Ledger' : 'Zero Dues',
                      isPositive: totalPendingDues == 0,
                      icon: Icons.money_off_csred_rounded,
                      color: AppColors.warning,
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Draft Bills',
                      value: '${parkedCarts.length} Parked',
                      trend: 'Active Queue',
                      isPositive: true,
                      icon: Icons.receipt_rounded,
                      color: Colors.indigo,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 📈 3. Row: Spline Sales Charts (65%) + AI Advisor Insights (35%)
            LayoutBuilder(
              builder: (context, constraints) {
                final isVertical = constraints.maxWidth < 1100;
                final contents = [
                  // ─── Chart Container ───
                  Expanded(
                    flex: isVertical ? 0 : 7,
                    child: _buildChartCard(context, isDark, chartData),
                  ),
                  if (!isVertical) const SizedBox(width: 24),
                  if (isVertical) const SizedBox(height: 24),
                  // ─── AI System Advisor Container ───
                  Expanded(
                    flex: isVertical ? 0 : 3,
                    child: _buildAiAdvisorCard(context, isDark, products, customers, shopProfile),
                  ),
                ];

                return isVertical
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: contents.map((e) => e is Expanded ? e.child : e).toList(),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: contents,
                      );
              },
            ),
            const SizedBox(height: 24),

            // 🚀 4. Quick Operational Shortcuts
            Text(
              'Operations Launchpad',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 5 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildShortcutTile(
                  context,
                  title: 'Inventory',
                  subtitle: 'Lookup & Catalog',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.accent,
                  onTap: () => context.go(RouteNames.inventory),
                ),
                _buildShortcutTile(
                  context,
                  title: 'Sales Ledger',
                  subtitle: 'Daily Transactions',
                  icon: Icons.assessment_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.go(RouteNames.salesReports),
                ),
                _buildShortcutTile(
                  context,
                  title: 'Cash Float',
                  subtitle: 'Register Drawer',
                  icon: Icons.wallet_rounded,
                  color: Colors.orange.shade700,
                  onTap: () => context.go(RouteNames.cashDrawer),
                ),
                _buildShortcutTile(
                  context,
                  title: 'VIP CRM',
                  subtitle: 'Customer base',
                  icon: Icons.people_rounded,
                  color: Colors.deepPurple,
                  onTap: () => context.go(RouteNames.crm),
                ),
                _buildShortcutTile(
                  context,
                  title: 'Terminal',
                  subtitle: 'System Config',
                  icon: Icons.tune_rounded,
                  color: Colors.grey.shade700,
                  onTap: () => context.go(RouteNames.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.shade200.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Icon Container + Outward Arrow Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          // Value & Title Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              // Trend Badge Row
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'than last month',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, bool isDark, List<_SalesData> chartData) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hourly Sales Momentum',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Real-time visual tracking of transaction volume',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: const CategoryAxis(
                majorGridLines: MajorGridLines(width: 0),
                labelStyle: TextStyle(fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                numberFormat: NumberFormat.compactSimpleCurrency(locale: 'en_IN', decimalDigits: 0),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              tooltipBehavior: TooltipBehavior(enable: true, header: 'Sales Revenue'),
              series: <CartesianSeries<_SalesData, String>>[
                SplineAreaSeries<_SalesData, String>(
                  dataSource: chartData,
                  xValueMapper: (_SalesData sales, _) => sales.hour,
                  yValueMapper: (_SalesData sales, _) => sales.revenue,
                  name: 'Sales Revenue',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: AppColors.primary,
                  borderWidth: 2.5,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    shape: DataMarkerType.circle,
                    color: Colors.white,
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdvisorCard(
    BuildContext context,
    bool isDark,
    List<ProductModel> products,
    List<CustomerModel> customers,
    ShopCategory shopProfile,
  ) {
    // 1. Compute dynamic Low Stock Insight
    final lowStockProducts = products.where((p) => p.currentStock <= 5).toList();
    final lowStockInsight = lowStockProducts.isNotEmpty
        ? _AdvisorInsightData(
            title: 'Predictive Reorder Alert',
            desc: "Stock for '${lowStockProducts.first.name}' is low (${lowStockProducts.first.currentStock} left). Estimate running out in 2 days. Settle replenishment order.",
            statusColor: AppColors.warning,
          )
        : const _AdvisorInsightData(
            title: 'Inventory Stocks Balanced',
            desc: 'All product SKUs currently satisfy catalog safety levels. No immediate low-stock triggers active.',
            statusColor: AppColors.success,
          );

    // 2. Compute dynamic VIP CRM Outstanding Balance Insight
    final outstandingCustomers = [...customers]..sort((a, b) => b.pendingDues.compareTo(a.pendingDues));
    final hasDues = outstandingCustomers.isNotEmpty && outstandingCustomers.first.pendingDues > 0;
    final crmInsight = hasDues
        ? _AdvisorInsightData(
            title: 'Outstanding Dues Remittance',
            desc: "VIP Customer '${outstandingCustomers.first.name}' has ₹${outstandingCustomers.first.pendingDues.toStringAsFixed(0)} pending ledger balance. Settle dues from CRM VIP panel.",
            statusColor: AppColors.primary,
          )
        : const _AdvisorInsightData(
            title: 'Ledger Accounts Clear',
            desc: 'No critical outstanding dues recorded across VIP customer segment rosters.',
            statusColor: AppColors.success,
          );

    // 3. Compute dynamic Shop-Type Operations Context Insight
    late final _AdvisorInsightData industryInsight;
    switch (shopProfile) {
      case ShopCategory.pharmacy:
        industryInsight = const _AdvisorInsightData(
          title: 'Batch Expiry Inspection',
          desc: 'Pharmacy batch trackers are scanning for near-expiry schedules. Keep safety dates verified.',
          statusColor: AppColors.secondary,
        );
        break;
      case ShopCategory.garments:
        industryInsight = const _AdvisorInsightData(
          title: 'Size Matrix Momentum',
          desc: 'Garments grid is balancing size-variants. Large and Medium stocks are trending fast.',
          statusColor: AppColors.secondary,
        );
        break;
      case ShopCategory.bakery:
        industryInsight = const _AdvisorInsightData(
          title: 'Fresh Stock Rotation',
          desc: 'Bakery shelf-life trackers suggest rapid batch rotation for fresh baked items.',
          statusColor: AppColors.secondary,
        );
        break;
      case ShopCategory.jewellery:
        industryInsight = const _AdvisorInsightData(
          title: 'Bullion Margin Adjuster',
          desc: 'Jewellery profiles show spot bullion updates. Dynamic margins balanced for sales checkout.',
          statusColor: AppColors.secondary,
        );
        break;
      case ShopCategory.kirana:
      default:
        industryInsight = const _AdvisorInsightData(
          title: 'FMCG Velocity Alert',
          desc: 'General Retail FMCG items registered peak velocity. Dynamic safety multipliers updated.',
          statusColor: AppColors.secondary,
        );
        break;
    }

    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lightbulb_rounded, color: Colors.amber.shade800, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI System Advisor',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildAdvisorInsight(
                  title: lowStockInsight.title,
                  desc: lowStockInsight.desc,
                  statusColor: lowStockInsight.statusColor,
                ),
                _buildAdvisorInsight(
                  title: crmInsight.title,
                  desc: crmInsight.desc,
                  statusColor: crmInsight.statusColor,
                ),
                _buildAdvisorInsight(
                  title: industryInsight.title,
                  desc: industryInsight.desc,
                  statusColor: industryInsight.statusColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Request Custom Insights',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdvisorInsight({
    required String title,
    required String desc,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildShortcutTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndustryConsole(BuildContext context, ShopCategory category, bool isDark) {
    IconData icon;
    String title;
    String subtitle;
    List<Widget> actions;
    Color color;

    switch (category) {
      case ShopCategory.pharmacy:
        icon = Icons.health_and_safety_rounded;
        title = '💊 PHARMACY & BATCH METRIC INTEGRITY';
        subtitle = '3 products are approaching near-expiry threshold (under 90 days). Batch registers are locked offline.';
        color = Colors.teal;
        actions = [
          _ConsoleAction(
            label: 'View Near-Expiry Ledger',
            icon: Icons.assignment_late_rounded,
            onTap: () => context.go(RouteNames.inventory),
            color: Colors.teal,
          ),
          const SizedBox(width: 12),
          _ConsoleAction(
            label: 'Verify H1 Schedule Logs',
            icon: Icons.security_rounded,
            onTap: () {},
            color: Colors.grey,
          ),
        ];
        break;
      case ShopCategory.garments:
        icon = Icons.dry_cleaning_rounded;
        title = '👕 GARMENTS MATRIX & VARIANTS PORTAL';
        subtitle = 'Sizing grid (XS-XXL) and colorways synced. 12 fashion catalog variations flagged with negative inventory.';
        color = AppColors.primary;
        actions = [
          _ConsoleAction(
            label: 'Open Size Matrix Editor',
            icon: Icons.grid_view_rounded,
            onTap: () => context.go(RouteNames.inventory),
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _ConsoleAction(
            label: 'Manage Barcode Bundles',
            icon: Icons.barcode_reader,
            onTap: () {},
            color: Colors.grey,
          ),
        ];
        break;
      case ShopCategory.bakery:
        icon = Icons.bakery_dining_rounded;
        title = '🍞 BAKERY BATCHES & PERISHABLE COUNTER';
        subtitle = 'Active baking batch #BKB-204 was checked in at 05:00 AM. 4 items flagged with perishable warning alerts.';
        color = Colors.orange;
        actions = [
          _ConsoleAction(
            label: 'Verify Production Batches',
            icon: Icons.hourglass_bottom_rounded,
            onTap: () => context.go(RouteNames.inventory),
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _ConsoleAction(
            label: 'Audit Wastage Logs',
            icon: Icons.delete_sweep_rounded,
            onTap: () {},
            color: Colors.grey,
          ),
        ];
        break;
      case ShopCategory.jewellery:
        icon = Icons.diamond_rounded;
        title = '💎 JEWELLERY METAL RATE & MAKING LEDGER';
        subtitle = 'Live market bullion rate node: Gold 22K (916) is trading at ₹6,738/g. Auto-calculate making charges enabled.';
        color = Colors.amber.shade700;
        actions = [
          _ConsoleAction(
            label: 'बुलियन Rate Node settings',
            icon: Icons.trending_up_rounded,
            onTap: () {},
            color: Colors.amber.shade800,
          ),
          const SizedBox(width: 12),
          _ConsoleAction(
            label: 'Update Making Surcharges',
            icon: Icons.percent_rounded,
            onTap: () {},
            color: Colors.grey,
          ),
        ];
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingConsole(BuildContext context, OnboardingState state, bool isDark) {
    final progress = state.progressPercentage;
    final percentVal = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚀 QUICK CASHIER ONBOARDING GUIDE',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Complete these quick steps to master the RathTech high-speed terminal.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                onPressed: () => ref.read(onboardingProvider.notifier).dismiss(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar Row
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$percentVal% Completed',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Steps checklist
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final stepsList = [
                _buildStepItem(
                  context: context,
                  isCompleted: state.settingsCustomized,
                  label: 'Configure thermal print receipt & shop profile',
                  actionLabel: 'Go to Settings',
                  onTap: () => context.go(RouteNames.settings),
                  isDark: isDark,
                ),
                _buildStepItem(
                  context: context,
                  isCompleted: state.tamilSearchTried,
                  label: 'Try phonetic Tamil search toggle in cashier bill screen',
                  actionLabel: 'Go to Billing',
                  onTap: () => context.go(RouteNames.billing),
                  isDark: isDark,
                ),
                _buildStepItem(
                  context: context,
                  isCompleted: state.stockAdjusted,
                  label: 'Use rapid stock balance delta adjustment modal',
                  actionLabel: 'Go to Inventory',
                  onTap: () => context.go(RouteNames.inventory),
                  isDark: isDark,
                ),
                _buildStepItem(
                  context: context,
                  isCompleted: state.pdfExported,
                  label: 'Compile a visual PDF ledger report or Excel file',
                  actionLabel: 'Go to Reports',
                  onTap: () => context.go(RouteNames.salesReports),
                  isDark: isDark,
                ),
              ];

              if (isWide) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  childAspectRatio: 5.5,
                  children: stepsList,
                );
              } else {
                return Column(
                  children: stepsList.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: w,
                  )).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required BuildContext context,
    required bool isCompleted,
    required String label,
    required String actionLabel,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF374151) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
                    color: isCompleted
                        ? Colors.grey.shade500
                        : (isDark ? Colors.white : AppColors.textPrimaryLight),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      '$actionLabel →',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            Colors.amber.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_empty_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏳ Free Trial Period Active — 11 Days Remaining',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unlock unlimited cloud backups, automated data archives, custom barcodes designer, and multi-branch operations console.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => showPremiumPaywallDialog(context),
            child: Text(
              'Upgrade Now',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ConsoleAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesData {
  final String hour;
  final double revenue;
  _SalesData(this.hour, this.revenue);
}

class _AdvisorInsightData {
  final String title;
  final String desc;
  final Color statusColor;

  const _AdvisorInsightData({
    required this.title,
    required this.desc,
    required this.statusColor,
  });
}

