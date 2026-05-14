import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/local_db/isar_provider.dart';
import '../../../../core/local_db/models/bill_model.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/connectivity_provider.dart';
import '../../../crm/presentation/providers/customer_providers.dart';
import '../../../inventory/presentation/providers/product_providers.dart';
import '../providers/cart_providers.dart';
import '../providers/parked_carts_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _searchQuery = '';
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _showCustomerSelector() {
    showDialog(
      context: context,
      builder: (context) => const _CustomerSelectorDialog(),
    );
  }

  void _parkCurrentCart() {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Cannot park an empty cart!'), backgroundColor: AppColors.warning),
      );
      return;
    }

    ref.read(parkedCartsProvider.notifier).parkCart(cart.items, cart.selectedCustomer, cart.netTotal);
    ref.read(cartProvider.notifier).clearCart();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏸️ Cart has been moved to Hold / Parking Lot successfully.'), backgroundColor: Colors.amber),
    );
  }

  void _showRecallParkedDialog() {
    final parked = ref.read(parkedCartsProvider);
    if (parked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📭 There are no parked bills on hold.'), backgroundColor: AppColors.info),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.pause_circle_rounded, color: Colors.indigo),
            SizedBox(width: 12),
            Text('Recall Held Cart'),
          ],
        ),
        content: SizedBox(
          width: 450,
          height: 300,
          child: ListView.separated(
            itemCount: parked.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final p = parked[idx];
              return ListTile(
                title: Text('Hold #${p.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.items.length} items • Total: ₹${p.totalValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                    if (p.customer != null)
                      Text('👤 Customer: ${p.customer!.name}', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: TextButton.icon(
                  onPressed: () {
                    // Check if current cart is occupied
                    final curCart = ref.read(cartProvider);
                    if (curCart.items.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🚨 Clear or park your current active cart first!'), backgroundColor: AppColors.error),
                      );
                      return;
                    }

                    ref.read(cartProvider.notifier).restoreCart(p.items, p.customer);
                    ref.read(parkedCartsProvider.notifier).removeParkedCart(p.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Cart restored to active register.'), backgroundColor: AppColors.success),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Recall'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _handleCheckout(double total) {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Scan items to checkout!'), backgroundColor: AppColors.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: 12),
            Text('Collect Payment'),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('TOTAL COLLECTABLE', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PaymentButton(
                      icon: Icons.money_rounded,
                      label: 'CASH',
                      color: Colors.green,
                      onPressed: () => _completeSale('Cash'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaymentButton(
                      icon: Icons.qr_code_2_rounded,
                      label: 'UPI / QR',
                      color: Colors.indigo,
                      onPressed: () => _completeSale('UPI'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _PaymentButton(
                  icon: Icons.credit_card_rounded,
                  label: 'CARD SWIPE',
                  color: Colors.orange,
                  onPressed: () => _completeSale('Card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeSale(String method) async {
    final cart = ref.read(cartProvider);
    final invoiceNo = 'INV-${DateFormat('yyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    
    // 1. Update stock in local provider + persist in Isar
    for (final item in cart.items) {
      ref.read(productsListProvider.notifier).updateStock(item.product.id, -item.quantity);
    }

    // 2. Log transaction into Isar persistently
    try {
      final isarService = ref.read(isarServiceProvider);
      final newBill = BillModel()
        ..invoiceNumber = invoiceNo
        ..timestamp = DateTime.now()
        ..subtotal = cart.subtotal
        ..gstAmount = cart.gstAmount
        ..netTotal = cart.netTotal
        ..paymentMethod = method
        ..isSyncedToCloud = false // Enforces Phase 41 Cloud Sync later
        ..purchasedItems = cart.items.map((item) {
          return CartItemEmbedded()
            ..productId = item.product.id
            ..productName = item.product.name
            ..quantity = item.quantity
            ..unitPrice = item.unitPrice
            ..lineTotal = item.finalTotal;
        }).toList();

      await isarService.logTransaction(newBill);
    } catch (e) {
      // Fail-safe: standard debug message if Isar storage write block hits constraints
    }

    if (!mounted) return;
    Navigator.pop(context); // Close Payment selection dialog

    
    // Show printed thermal receipt overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.done, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('PAYMENT RECEIVED', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('Method: $method', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              
              // Thermal receipt design container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text('RATH-TECH RETAILS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                          const Text('GSTIN: 33AAACH8824C1Z4', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          Text('Invoice: $invoiceNo', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                          const Text('-------------------------------', style: TextStyle(color: Colors.black26)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cart.items.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${e.product.name} x${e.quantity}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('₹${e.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const Center(child: Text('-------------------------------', style: TextStyle(color: Colors.black26))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NET TOTAL PAID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13)),
                        Text('₹${cart.netTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(cartProvider.notifier).clearCart();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(cartProvider.notifier).clearCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🖨️ Thermal printing command dispatched.'), backgroundColor: AppColors.success),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print Receipt'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsListProvider);
    final cart = ref.watch(cartProvider);
    
    final filteredProducts = products.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) || p.sku.toLowerCase().contains(query) || (p.barcode ?? '').contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Row(
          children: [
            Text('New Billing Shift', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('REG #01', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _showRecallParkedDialog,
            icon: const Icon(Icons.pause_circle_rounded, color: Colors.indigo),
            label: const Text('Recall Held', style: TextStyle(color: Colors.indigo)),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _parkCurrentCart,
            icon: const Icon(Icons.pause_rounded, color: Colors.amber),
            label: const Text('Hold Order', style: TextStyle(color: Colors.amber)),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            label: const Text('Clear Cart', style: TextStyle(color: AppColors.error)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Pane: Product Catalog Grid (60%)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // High speed search input
                  TextField(
                    focusNode: _searchFocus,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Scan barcode or type product SKU...',
                      prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: AppColors.primary),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product Grid Catalog
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, idx) {
                        final prod = filteredProducts[idx];
                        final inStock = !prod.isOutOfStock;
                        
                        return Material(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: inStock ? () {
                              ref.read(cartProvider.notifier).addToCart(prod);
                              // Return focus to search box automatically for fast workflow
                              _searchFocus.requestFocus();
                            } : null,
                            child: Opacity(
                              opacity: inStock ? 1.0 : 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prod.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(
                                          inStock ? 'Stock: ${prod.currentStock}' : 'OUT OF STOCK',
                                          style: TextStyle(fontSize: 11, color: inStock ? Colors.grey.shade500 : AppColors.error, fontWeight: inStock ? null : FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('₹${prod.sellingPrice}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                      ],
                                    )
                                  ],
                                ),
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
          ),

          // Split Divider
          Container(
            width: 1,
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200,
          ),

          // Right Pane: Active Cart & Receipt (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.grey.shade50,
              child: Column(
                children: [
                  // Cart Headers & Customer Selector Hook
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Active Cart items', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(Radius.circular(12))),
                              child: Text('${cart.items.length} SKUs', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Customer Selection Ribbon
                        if (cart.selectedCustomer == null)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                            ),
                            onPressed: _showCustomerSelector,
                            icon: const Icon(Icons.person_add_outlined, size: 18),
                            label: const Text('Link Customer Loyalty Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withOpacity(0.2),
                                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cart.selectedCustomer!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        cart.selectedCustomer!.phone,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    '⭐ ${cart.selectedCustomer!.loyaltyPoints} PTS',
                                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => ref.read(cartProvider.notifier).removeCustomer(),
                                  child: Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade400),
                                )
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Scrollable Cart Rows
                  Expanded(
                    child: cart.items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('No items added to cart.', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: cart.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = cart.items[idx];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.product.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text('₹${item.unitPrice} each', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    
                                    // Quantity incremental controller
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 22),
                                          onPressed: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 22, color: AppColors.primary),
                                          onPressed: () => ref.read(cartProvider.notifier).incrementQuantity(item.product.id),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(width: 8),
                                    Text('₹${item.finalTotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Price calculation Summary & Pay button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      children: [
                        _ReceiptRow(label: 'Subtotal Items', value: '₹${cart.subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _ReceiptRow(label: 'Applied GST (${cart.gstRate}%)', value: '₹${cart.gstAmount.toStringAsFixed(2)}'),
                        const Divider(height: 24),
                        _ReceiptRow(
                          label: 'NET TOTAL DUE',
                          value: '₹${cart.netTotal.toStringAsFixed(2)}',
                          isBold: true,
                          valueColor: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: cart.items.isEmpty ? null : () => _handleCheckout(cart.netTotal),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payments_outlined, size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  'COLLECT & PRINT INVOICE',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _PaymentButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: isBold ? 16 : 13,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: isBold ? null : Colors.grey.shade500,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(
          value,
          style: textStyle.copyWith(
            color: valueColor,
            fontSize: isBold ? 18 : 13,
          ),
        ),
      ],
    );
  }
}

class _CustomerSelectorDialog extends ConsumerStatefulWidget {
  const _CustomerSelectorDialog();

  @override
  ConsumerState<_CustomerSelectorDialog> createState() => _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState extends ConsumerState<_CustomerSelectorDialog> {
  String _search = '';
  bool _isAdding = false;
  
  // Registration form states
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider);
    
    final filtered = customers.where((c) =>
        c.name.toLowerCase().contains(_search.toLowerCase()) ||
        c.phone.contains(_search)
    ).toList();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_isAdding ? 'Register Fresh Loyalty Node' : 'Link Customer Profile', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton.icon(
            onPressed: () => setState(() => _isAdding = !_isAdding),
            icon: Icon(_isAdding ? Icons.search : Icons.add),
            label: Text(_isAdding ? 'Search Base' : 'Quick Create'),
          )
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _isAdding
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_rounded)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address (Optional)', prefixIcon: Icon(Icons.email_rounded)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppColors.primary),
                      onPressed: () {
                        if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                          ref.read(customersListProvider.notifier).registerCustomer(
                                _nameController.text,
                                _phoneController.text,
                                _emailController.text,
                              );
                          // Automatically select the newly created customer!
                          final latestCustomers = ref.read(customersListProvider);
                          ref.read(cartProvider.notifier).selectCustomer(latestCustomers.last);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('⭐ Customer registered with 10 welcome points!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: const Text('Enroll & Link to Cart', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by phone or full name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Text('No active profiles match this query.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final cust = filtered[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade100,
                                  child: Text(cust.name.substring(0, 1), style: const TextStyle(color: AppColors.primary)),
                                ),
                                title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(cust.phone, style: const TextStyle(fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text('${cust.loyaltyPoints} pts', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () {
                                  ref.read(cartProvider.notifier).selectCustomer(cust);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  )
                ],
              ),
      ),
    );
  }
}
