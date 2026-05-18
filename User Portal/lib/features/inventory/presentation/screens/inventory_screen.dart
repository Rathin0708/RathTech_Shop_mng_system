import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/models/product_model.dart';
import '../providers/product_providers.dart';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/widgets/premium_lock.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All Items';

  void _showRestockDialog(BuildContext context, ProductModel prod) {
    final controller = TextEditingController(text: '${prod.currentStock}');

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Adjust Stock Integrity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('SKU: ${prod.sku}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 24),

                Text(
                  'PHYSICAL ON-HAND COUNT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Rapid modifiers Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ModifierChip(label: '-5', onTap: () => _adjustCount(controller, -5)),
                    _ModifierChip(label: '-1', onTap: () => _adjustCount(controller, -1)),
                    _ModifierChip(label: '+1', onTap: () => _adjustCount(controller, 1)),
                    _ModifierChip(label: '+5', onTap: () => _adjustCount(controller, 5)),
                    _ModifierChip(label: '+20', onTap: () => _adjustCount(controller, 20)),
                  ],
                ),
              ],
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
                final finalCount = int.tryParse(controller.text) ?? 0;
                final variance = finalCount - prod.currentStock;

                ref.read(productsListProvider.notifier).updateStock(prod.id, variance);
                ref.read(onboardingProvider.notifier).completeStep('stockAdjusted');

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📋 Stock balanced for ${prod.name}. (Delta: ${variance >= 0 ? '+' : ''}$variance units)'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Commit Update'),
            ),
          ],
        );
      },
    );
  }

  void _adjustCount(TextEditingController controller, int amt) {
    final current = int.tryParse(controller.text) ?? 0;
    final updated = current + amt;
    controller.text = (updated < 0 ? 0 : updated).toString();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsListProvider);
    final isOnline = ref.watch(connectivityServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userRole = ref.watch(authControllerProvider).user?.role ?? UserRole.admin;
    final canEditStock = userRole == UserRole.admin ||
        userRole == UserRole.superAdmin ||
        userRole == UserRole.manager ||
        userRole == UserRole.cashier;
    final canAddDelete = userRole == UserRole.admin ||
        userRole == UserRole.superAdmin ||
        userRole == UserRole.manager;

    // Dynamic list of categories based on catalog items
    final allCategories = ['All Items', ...products.map((p) => p.category).toSet()];

    // Filter dataset
    final filteredProducts = products.where((p) {
      final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode ?? '').contains(_searchQuery);

      final matchesCat = _selectedCategory == 'All Items' || p.category == _selectedCategory;

      return matchesQuery && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Delegate to shell
      body: Column(
        children: [
          // 🏷️ 1. Modern Top Ribbon Header (replaces AppBar)
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
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Store Inventory Catalog',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (canAddDelete)
                      PremiumLock(
                        premiumExplanation: 'Unlock Custom Barcode Designer',
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Generate Custom Barcodes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    if (canAddDelete) const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isOnline ? () {} : null,
                      icon: Icon(isOnline ? Icons.sync_rounded : Icons.cloud_off_rounded, size: 18),
                      label: Text(isOnline ? 'Cloud Synced' : 'Offline Mode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnline
                            ? (isDark ? AppColors.surfaceDark : Colors.white)
                            : Colors.grey.shade200,
                        foregroundColor: isOnline ? AppColors.success : Colors.grey.shade600,
                        elevation: 0,
                        side: BorderSide(color: isOnline ? AppColors.success.withValues(alpha: 0.3) : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📦 2. Split Workspace
          Expanded(
            child: Row(
              children: [
                // 📂 Categories Sidebar Navigator
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.grey.shade50,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: allCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final cat = allCategories[idx];
                      final isSelected = cat == _selectedCategory;

                      return Material(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  cat == 'All Items' ? Icons.layers_rounded : Icons.folder_rounded,
                                  color: isSelected ? AppColors.primary : Colors.grey.shade500,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.inter(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 📚 Product Cards Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search stock by SKU, barcode, or name...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  filled: true,
                                  fillColor: isDark ? AppColors.cardDark : Colors.white,
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
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📷 Device camera triggered for scanning.'),
                                    backgroundColor: AppColors.info,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text('Scan Product'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Responsive Grid View
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text('No inventory matches found in this category.', style: TextStyle(color: Colors.grey.shade500)),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.25,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, idx) {
                                    final prod = filteredProducts[idx];

                                    // Dynamic Health Indicator Styling
                                    Color cardBorder = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
                                    Color stockColor = Colors.green;
                                    String stockLabel = 'Healthy Stock (${prod.currentStock})';
                                    IconData stockIcon = Icons.check_circle_outline_rounded;

                                    if (prod.isOutOfStock) {
                                      cardBorder = AppColors.error.withValues(alpha: 0.5);
                                      stockColor = AppColors.error;
                                      stockLabel = 'OUT OF STOCK';
                                      stockIcon = Icons.error_outline_rounded;
                                    } else if (prod.isLowStock) {
                                      cardBorder = Colors.orange.withValues(alpha: 0.5);
                                      stockColor = Colors.orange.shade700;
                                      stockLabel = 'LOW STOCK (${prod.currentStock})';
                                      stockIcon = Icons.warning_amber_rounded;
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.surfaceDark : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: cardBorder, width: (prod.isOutOfStock || prod.isLowStock) ? 1.5 : 1),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Top Row: Category + Status
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    prod.category.toUpperCase(),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: stockColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(stockIcon, size: 12, color: stockColor),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          stockLabel,
                                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stockColor),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Mid Row: Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  prod.name,
                                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                 Row(
                                                   children: [
                                                     Text('SKU: ${prod.sku}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                                   ],
                                                 ),
                                              ],
                                            ),
                                          ),

                                          // Bottom Row: Price & Adjust
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '₹${prod.sellingPrice.toStringAsFixed(2)}',
                                                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                              if (canEditStock)
                                               IconButton.filledTonal(
                                                style: IconButton.styleFrom(
                                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                  foregroundColor: AppColors.primary,
                                                ),
                                                onPressed: () => _showRestockDialog(context, prod),
                                                icon: const Icon(Icons.edit_note_rounded, size: 20),
                                                tooltip: 'Update Stock Count',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
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

class _ModifierChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ModifierChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNeg = label.contains('-');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isNeg ? Colors.red.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
          border: Border.all(color: isNeg ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isNeg ? Colors.red.shade700 : Colors.green.shade700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
