import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/tenant_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/tenant_providers.dart';

class TenantsListScreen extends ConsumerStatefulWidget {
  const TenantsListScreen({super.key});

  @override
  ConsumerState<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends ConsumerState<TenantsListScreen> {
  String _searchQuery = '';

  void _showTenantDetailDrawer(BuildContext context, TenantModel tenant) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Drawer',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final slideTransition = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
        
        return SlideTransition(
          position: slideTransition,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Theme.of(context).cardTheme.color,
              elevation: 16,
              child: Container(
                width: 480,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200)),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drawer Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Enterprise Tenant Profile', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.5)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Profile Box
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(tenant.businessName[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tenant.businessName, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text('Shop ID: ${tenant.id}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    Text('DEPLOYMENT FOOTPRINT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey)),
                    const SizedBox(height: 16),
                    
                    // Multi-Branch and SKU grids
                    Row(
                      children: [
                        _DetailStatCard(title: 'Active Branches', value: '2 Locations', subValue: 'Max Allowed: 5', icon: Icons.storefront_rounded),
                        const SizedBox(width: 16),
                        _DetailStatCard(title: 'Catalog Data', value: '1,420 SKUs', subValue: 'Cloud Space: 12MB', icon: Icons.inventory_2_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _DetailStatCard(title: 'Device Leases', value: '3 Activated', subValue: 'Pro Tier (Limit: 3)', icon: Icons.devices_rounded),
                        const SizedBox(width: 16),
                        _DetailStatCard(title: 'Daily Transacts', value: '142 Bills', subValue: 'Avg Vol: ₹42k/day', icon: Icons.bar_chart_rounded),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Text('OPERATIONAL DIAGNOSTICS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey)),
                    const SizedBox(height: 16),
                    
                    // Live Connection Observer Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _DiagnosticRow(label: 'Main Branch Gateway', value: 'Active Pings', isOk: true),
                          const Divider(height: 20),
                          _DiagnosticRow(label: 'Sync Latency', value: '< 200ms', isOk: true),
                          const Divider(height: 20),
                          _DiagnosticRow(label: 'Database Heath', value: '100% Solid', isOk: true),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Bottom Actions Block
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📥 Generating PDF audit log for this tenant...'), backgroundColor: AppColors.info),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export Shop Audit logs'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddTenantDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String owner = '';
    String email = '';
    String phone = '';
    ShopCategory selectedCat = ShopCategory.general;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Onboard New SaaS Tenant'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Business Name', hintText: 'e.g. RathTech Mart'),
                    onChanged: (v) => name = v,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Owner Full Name'),
                    onChanged: (v) => owner = v,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Email Address'),
                          onChanged: (v) => email = v,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Contact Phone'),
                          onChanged: (v) => phone = v,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ShopCategory>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(labelText: 'Business Category'),
                    items: ShopCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) selectedCat = v;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newTenant = TenantModel(
                  id: 'ten_${DateTime.now().millisecondsSinceEpoch}',
                  businessName: name,
                  ownerName: owner,
                  contactEmail: email,
                  contactPhone: phone,
                  category: selectedCat,
                  status: TenantStatus.trial,
                  currentPlanId: 'trial_14d',
                  subscriptionExpiresAt: DateTime.now().add(const Duration(days: 14)),
                  createdAt: DateTime.now(),
                );
                ref.read(tenantsListProvider.notifier).addTenant(newTenant);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New tenant provisioned successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Create & Send Mail'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenants = ref.watch(tenantsListProvider);
    
    final filteredTenants = tenants.where((t) {
      final query = _searchQuery.toLowerCase();
      return t.businessName.toLowerCase().contains(query) ||
             (t.ownerName ?? '').toLowerCase().contains(query) ||
             t.contactEmail.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Store Tenants',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Onboard, manage restrictions, and view licenses for your global shops.',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTenantDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Provision Tenant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. Actions/Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by shop name, owner or email...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('More Filters'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Main Modern Data Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade800),
                      columnSpacing: 40,
                      horizontalMargin: 24,
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.grey.shade50,
                      ),
                      columns: const [
                        DataColumn(label: Text('SHOP BUSINESS')),
                        DataColumn(label: Text('CATEGORY')),
                        DataColumn(label: Text('SUBSCRIPTION')),
                        DataColumn(label: Text('EXPIRES ON')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: filteredTenants.map((t) {
                        return DataRow(cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  radius: 16,
                                  child: Text(
                                    t.businessName[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.businessName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    Text(t.ownerName ?? 'No Owner Listed', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(t.category.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          DataCell(Text(t.currentPlanId.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13))),
                          DataCell(Text(DateFormat('MMM dd, yyyy').format(t.subscriptionExpiresAt), style: const TextStyle(fontSize: 13))),
                          DataCell(_StatusBadge(status: t.status)),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showTenantDetailDrawer(context, t),
                                  tooltip: 'View Full Analytics & Edit',
                                ),
                                PopupMenuButton<TenantStatus>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                                  onSelected: (s) => ref.read(tenantsListProvider.notifier).updateStatus(t.id, s),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: TenantStatus.active, child: Text('Mark Active')),
                                    const PopupMenuItem(value: TenantStatus.suspended, child: Text('Suspend Business')),
                                    const PopupMenuItem(value: TenantStatus.blocked, child: Text('Block Fully')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TenantStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TenantStatus.active:
        color = AppColors.success;
        break;
      case TenantStatus.trial:
        color = AppColors.info;
        break;
      case TenantStatus.suspended:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;

  const _DetailStatCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subValue, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOk ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOk ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
