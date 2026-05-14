import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/models/product_model.dart';
import '../providers/product_providers.dart';

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
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Inventory Count Adjust'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('SKU: ${prod.sku}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 24),
              
              const Text('PHYSICAL ON-HAND COUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black54, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final finalCount = int.tryParse(controller.text) ?? 0;
              final variance = finalCount - prod.currentStock;
              
              ref.read(productsListProvider.notifier).updateStock(prod.id, variance);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📋 Stock balanced for ${prod.name}. (Delta: ${variance >= 0 ? '+' : ''}$variance units)'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Commit Adjustment'),
          ),
        ],
      ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text(
          'Offline Stock Catalog',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Quick scan simulator
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📷 Triggering device barcode scanner camera...'), backgroundColor: AppColors.info),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Simulate Scan'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Column: Categories Sidebar Navigator (touch friendly)
          Container(
            width: 240,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200,
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
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.primary) : null,
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : null,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Right Workspace: Grid with search and sync status
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Search input bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search by SKU, barcode or product title...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Sync indicator / Button -> Dynamically Rendered
                      ElevatedButton.icon(
                        onPressed: isOnline ? () {} : null,
                        icon: Icon(isOnline ? Icons.sync_rounded : Icons.cloud_off_rounded, size: 18),
                        label: Text(isOnline ? 'Pull Cloud Updates' : 'Offline Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOnline 
                              ? (Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white)
                              : Colors.grey.shade200,
                          foregroundColor: isOnline ? AppColors.success : Colors.grey.shade500,
                          elevation: 0,
                          side: BorderSide(color: isOnline ? AppColors.success.withOpacity(0.4) : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Responsive Cards Grid View
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Text('No matching items in the active catalog.', style: TextStyle(color: Colors.grey.shade500)),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, idx) {
                              final prod = filteredProducts[idx];
                              
                              Color cardBorder = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200;
                              Color stockBadge = AppColors.success;
                              String stockLabel = '${prod.currentStock} available';
                              
                              if (prod.isOutOfStock) {
                                cardBorder = AppColors.error;
                                stockBadge = AppColors.error;
                                stockLabel = 'OUT OF STOCK';
                              } else if (prod.isLowStock) {
                                cardBorder = AppColors.warning;
                                stockBadge = AppColors.warning;
                                stockLabel = 'LOW STOCK (${prod.currentStock})';
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorder, width: 1.5),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top row: Icon/Cat & Stock Badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(prod.category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: stockBadge.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                          child: Text(stockLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stockBadge)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Title & Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prod.name,
                                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SKU: ${prod.sku}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Bottom Price & Quick Edit Stock
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${prod.sellingPrice.toStringAsFixed(2)}',
                                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        IconButton.filledTonal(
                                          onPressed: () => _showRestockDialog(context, prod),
                                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                                          tooltip: 'Adjust Stock Level',
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
          color: isNeg ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
          border: Border.all(color: isNeg ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
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
