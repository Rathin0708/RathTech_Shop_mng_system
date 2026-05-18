import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/customer_providers.dart';

class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});

  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> {
  String _searchQuery = '';
  String _selectedSegment = 'All Members'; // 'All Members', 'VIP Tier', 'Pending Dues'
  CustomerModel? _selectedCustomer;

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Enroll New VIP Customer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Full Name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter phone number';
                      if (v.trim().length < 10) return 'Enter a valid 10-digit mobile number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address (Optional)',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  ref.read(customersListProvider.notifier).registerCustomer(
                        nameController.text.trim(),
                        phoneController.text.trim(),
                        emailController.text.trim(),
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 New loyalty customer enrolled successfully! (+10 Welcome Points)'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Enroll Account'),
            ),
          ],
        );
      },
    );
  }

  void _showSettleDuesDialog(CustomerModel customer) {
    final controller = TextEditingController(text: customer.pendingDues.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.price_check_rounded, color: AppColors.success),
              const SizedBox(width: 12),
              Text('Clear Pending Dues', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settle account dues balance for ${customer.name}.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text(
                    'PENDING BALANCE: ₹${customer.pendingDues.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Settle Payment Amount',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter settlement amount';
                      final amt = double.tryParse(v);
                      if (amt == null || amt <= 0) return 'Enter a valid positive number';
                      if (amt > customer.pendingDues) return 'Cannot pay more than outstanding dues';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  final amt = double.parse(controller.text);
                  ref.read(customersListProvider.notifier).settleDues(customer.id, amt);
                  
                  // Update current selected visual details
                  setState(() {
                    if (_selectedCustomer?.id == customer.id) {
                      _selectedCustomer = _selectedCustomer!.copyWith(
                        pendingDues: _selectedCustomer!.pendingDues - amt,
                      );
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('💸 Dues cleared successfully! Logged ₹${amt.toStringAsFixed(2)} payment.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Complete Settlement'),
            ),
          ],
        );
      },
    );
  }

  void _showLoyaltyAdjustmentDialog(CustomerModel customer) {
    final controller = TextEditingController(text: '50');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 12),
              Text('Award Loyalty Rewards', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Direct loyalty reward adjustment for ${customer.name}.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Award Points Count',
                      suffixText: 'Pts',
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter points count';
                      final pts = int.tryParse(v);
                      if (pts == null || pts <= 0) return 'Enter a valid positive integer';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  final pts = int.parse(controller.text);
                  ref.read(customersListProvider.notifier).addLoyaltyPoints(customer.id, pts);
                  
                  setState(() {
                    if (_selectedCustomer?.id == customer.id) {
                      _selectedCustomer = _selectedCustomer!.copyWith(
                        loyaltyPoints: _selectedCustomer!.loyaltyPoints + pts,
                      );
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⭐ Awarded $pts points to loyalty profile successfully!'),
                      backgroundColor: Colors.amber.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Award Points'),
            ),
          ],
        );
      },
    );
  }

  void _triggerSimulatedWhatsappInvoice(CustomerModel customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Synthesizing dynamic ledger invoice document...'),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📱 WhatsApp Ledger Remittance shared to customer +91 ${customer.phone}!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Calculate KPI Metrics
    final totalMembers = customers.length;
    final totalPoints = customers.fold(0, (sum, c) => sum + c.loyaltyPoints);
    final totalSpentVal = customers.fold(0.0, (sum, c) => sum + c.totalSpent);
    final totalOutstandingDues = customers.fold(0.0, (sum, c) => sum + c.pendingDues);

    // 2. Filter list
    final filteredCustomers = customers.where((c) {
      final matchesQuery = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.phone.contains(_searchQuery);
      if (!matchesQuery) return false;

      if (_selectedSegment == 'VIP Tier') {
        return c.isVip;
      } else if (_selectedSegment == 'Pending Dues') {
        return c.pendingDues > 0;
      }
      return true;
    }).toList();

    // Auto-select first customer if none is selected
    if (_selectedCustomer == null && filteredCustomers.isNotEmpty) {
      _selectedCustomer = filteredCustomers.first;
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Delegate to shell layout
      body: Column(
        children: [
          // 🏷️ 1. Modern Sub-Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go(RouteNames.dashboard),
                      tooltip: 'Return to POS Dashboard',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Store CRM & Loyalty Registry',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Enroll New Client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // 📊 2. Store CRM Metrics Tiles Row
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, top: 24),
            child: Row(
              children: [
                _KpiWidget(
                  title: 'Enrolled Members',
                  value: '$totalMembers Clients',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _KpiWidget(
                  title: 'Active Rewards Pool',
                  value: '$totalPoints Points',
                  icon: Icons.stars_rounded,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(width: 16),
                _KpiWidget(
                  title: 'Lifetime Member Spent',
                  value: '₹${totalSpentVal.toStringAsFixed(0)}',
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.success,
                ),
                const SizedBox(width: 16),
                _KpiWidget(
                  title: 'Outstanding Ledger Dues',
                  value: '₹${totalOutstandingDues.toStringAsFixed(0)}',
                  icon: Icons.error_outline_rounded,
                  color: AppColors.error,
                ),
              ],
            ),
          ),

          // ⚙️ 3. Main Workspace split panes
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT WORKSPACE: Filters & Customer List (60%)
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        // Search bar & Segment pills row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search members by name or mobile...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  filled: true,
                                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Segment filter buttons
                            _buildSegmentPill('All Members', isDark),
                            const SizedBox(width: 8),
                            _buildSegmentPill('VIP Tier', isDark),
                            const SizedBox(width: 8),
                            _buildSegmentPill('Pending Dues', isDark),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Customers grid/list
                        Expanded(
                          child: filteredCustomers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text('No loyalty accounts found for this criteria.', style: TextStyle(color: Colors.grey.shade500)),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.35,
                                  ),
                                  itemCount: filteredCustomers.length,
                                  itemBuilder: (context, idx) {
                                    final customer = filteredCustomers[idx];
                                    final isSelected = _selectedCustomer?.id == customer.id;

                                    return Material(
                                      color: isDark ? AppColors.surfaceDark : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          setState(() {
                                            _selectedCustomer = customer;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                              width: isSelected ? 2.0 : 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Top: Name and Badge
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          customer.name,
                                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(
                                                          '+91 ${customer.phone}',
                                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  // VIP Gold Label
                                                  if (customer.isVip)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'VIP GOLD',
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                                                      ),
                                                    )
                                                  else
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'MEMBER',
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              // Middle: Metrics summary
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Spent Val', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                                      const SizedBox(height: 2),
                                                      Text('₹${customer.totalSpent.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Loyalty Pts', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                          const SizedBox(width: 2),
                                                          Text('${customer.loyaltyPoints} Pts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              // Bottom: Outstanding Dues alert
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  if (customer.pendingDues > 0)
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 14),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Dues: ₹${customer.pendingDues.toStringAsFixed(0)}',
                                                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    )
                                                  else
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 14),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Clear Account',
                                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 14),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 32),
                  VerticalDivider(width: 1, color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                  const SizedBox(width: 32),

                  // RIGHT WORKSPACE: Premium Profile Detail Drawer (40%)
                  Expanded(
                    flex: 4,
                    child: _selectedCustomer == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.contact_phone_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('Select a customer card to inspect detailed ledger.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                              ],
                            ),
                          )
                        : _buildProfileDetailPanel(context, _selectedCustomer!, isDark),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSegmentPill(String segment, bool isDark) {
    final isSelected = _selectedSegment == segment;
    return Material(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _selectedSegment = segment),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF374151) : Colors.grey.shade300),
            ),
          ),
          child: Text(
            segment,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailPanel(BuildContext context, CustomerModel customer, bool isDark) {
    // Dynamic avatar color based on VIP tier
    final avatarBgColor = customer.isVip ? Colors.amber.shade100 : AppColors.primary.withValues(alpha: 0.1);
    final avatarColor = customer.isVip ? Colors.amber.shade800 : AppColors.primary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: avatarBgColor,
                  child: Icon(customer.isVip ? Icons.star_rounded : Icons.person_rounded, color: avatarColor, size: 36),
                ),
                const SizedBox(height: 16),
                Text(customer.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('+91 ${customer.phone}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                if (customer.email != null)
                  Text(customer.email!, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const SizedBox(height: 12),
                if (customer.isVip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text('VIP PREFERRED CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade900, letterSpacing: 0.5)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text('STANDARD CLIENT ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ledger & Dues Alert Section
          if (customer.pendingDues > 0) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outstanding Dues: ₹${customer.pendingDues.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.error)),
                        const SizedBox(height: 2),
                        Text('Customer has active bills marked as credit.', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () => _showSettleDuesDialog(customer),
                    child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Loyalty and Spending Progress
          Text(
            'LIFETIME REVENUE & LOYALTY TIER',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount Spent', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    Text('₹${customer.totalSpent.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (customer.totalSpent / 25000.0).clamp(0.0, 1.0),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
                    color: AppColors.success,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target for Gold tier', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    Text('₹25,000 max', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Loyalty Points', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text('${customer.loyaltyPoints} Points', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Launchers Grid
          Text(
            'CUSTOMER CRM OPERATIONS',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.star_border_rounded,
                  label: 'Award Loyalty',
                  subtitle: 'Direct Adjustment',
                  color: Colors.amber.shade800,
                  onTap: () => _showLoyaltyAdjustmentDialog(customer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp invoice',
                  subtitle: 'Share Statement',
                  color: AppColors.success,
                  onTap: () => _triggerSimulatedWhatsappInvoice(customer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onPressed: () {
                // Simulated spent modifier to add quick purchases
                ref.read(customersListProvider.notifier).recordPurchase(customer.id, 1500.0);
                
                setState(() {
                  if (_selectedCustomer?.id == customer.id) {
                    _selectedCustomer = _selectedCustomer!.copyWith(
                      totalSpent: _selectedCustomer!.totalSpent + 1500.0,
                      loyaltyPoints: _selectedCustomer!.loyaltyPoints + 15,
                    );
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🛍️ Simulated quick register purchase of ₹1,500.00 logged! (+15 Loyalty Points)'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: const Text('Simulate Shift Purchase (+₹1,500)'),
            ),
          )
        ],
      ),
    );
  }
}

class _KpiWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiWidget({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
