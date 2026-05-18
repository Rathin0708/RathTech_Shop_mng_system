import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/local_db/isar_provider.dart';
import '../../../../core/local_db/models/bill_model.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/shop_profile_provider.dart';
import '../../../../core/models/tenant_model.dart';
import '../../../../core/providers/onboarding_provider.dart';
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
  final _searchController = TextEditingController();
  bool _isTamilMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _isTamilMode = !_isTamilMode;
    });
    ref.read(onboardingProvider.notifier).completeStep('tamilSearchTried');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTamilMode ? '🔍 Smart Tamil phonetic search activated' : '🔍 Standard English search active'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        const SnackBar(
          content: Text('🚨 Cannot park an empty cart!'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ref.read(parkedCartsProvider.notifier).parkCart(cart.items, cart.selectedCustomer, cart.netTotal);
    ref.read(cartProvider.notifier).clearCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⏸️ Cart has been moved to Hold / Parking Lot successfully.'),
        backgroundColor: Colors.amber.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRecallParkedDialog() {
    final parked = ref.read(parkedCartsProvider);
    if (parked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📭 There are no parked bills on hold.'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_rounded, color: Colors.indigo),
            const SizedBox(width: 12),
            Text('Recall Held Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                title: Text('Hold Order #${p.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.items.length} items • Total: ₹${p.totalValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                    if (p.customer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('👤 Customer: ${p.customer!.name}', style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: AppColors.primary.withValues(alpha: 0.1), foregroundColor: AppColors.primary),
                  onPressed: () {
                    final curCart = ref.read(cartProvider);
                    if (curCart.items.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🚨 Clear or park your current active cart first!'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    ref.read(cartProvider.notifier).restoreCart(p.items, p.customer);
                    ref.read(parkedCartsProvider.notifier).removeParkedCart(p.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cart restored to active register.'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
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
        const SnackBar(
          content: Text('Cart is empty. Add items to checkout!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            const SizedBox(width: 12),
            Text('Complete Checkout Flow', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('TOTAL PAYABLE AMOUNT', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                      label: 'UPI QR',
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
                  label: 'CARD PAYMENT',
                  color: Colors.orange.shade800,
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

    // 1. Update stock
    for (final item in cart.items) {
      ref.read(productsListProvider.notifier).updateStock(item.product.id, -item.quantity);
    }

    // 2. Persist to Isar
    try {
      final isarService = ref.read(isarServiceProvider);
      final newBill = BillModel()
        ..invoiceNumber = invoiceNo
        ..timestamp = DateTime.now()
        ..subtotal = cart.subtotal
        ..gstAmount = cart.gstAmount
        ..netTotal = cart.netTotal
        ..paymentMethod = method
        ..isSyncedToCloud = false
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
      // fail-safe fallback log
    }

    if (!mounted) return;
    Navigator.pop(context); // Close payment options selection

    // Show printed receipt dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 32),
              ),
              const SizedBox(height: 16),
              Text('PAYMENT RECEIVED', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Settlement Method: $method', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.grey.shade50,
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text('RATH-TECH SAAS RETAIL', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15)),
                          const Text('GSTIN: 33AAACH8824C1Z4', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('Receipt: $invoiceNo', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const Divider(height: 24),
                        ],
                      ),
                    ),
                    ...cart.items.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${e.product.name} x${e.quantity}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('₹${e.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NET TOTAL SETTLED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('₹${cart.netTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(cartProvider.notifier).clearCart();
                        _searchFocus.requestFocus();
                      },
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(cartProvider.notifier).clearCart();
                        _searchFocus.requestFocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🖨️ Thermal receipt dispatch signal triggered.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Invoice'),
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

  void _handleKeyStroke(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f12) {
        final cart = ref.read(cartProvider);
        if (cart.items.isNotEmpty) {
          _handleCheckout(cart.netTotal);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f8) {
        _parkCurrentCart();
      } else if (event.logicalKey == LogicalKeyboardKey.f9) {
        _showRecallParkedDialog();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _searchController.clear();
        setState(() => _searchQuery = '');
        _searchFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsListProvider);
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopProfile = ref.watch(shopProfileProvider);

    final filteredProducts = products.where((p) {
      final query = _searchQuery.toLowerCase().trim();
      String mappedQuery = query;
      
      if (_isTamilMode && query.isNotEmpty) {
        // High-fidelity Tamil Unicode and Phonetic Transliteration Dictionary
        final transliterationMap = {
          'உப்பு': 'salt',
          'uppu': 'salt',
          'சர்க்கரை': 'sugar',
          'sarkarai': 'sugar',
          'sakkarai': 'sugar',
          'பால்': 'milk',
          'paal': 'milk',
          'நெய்': 'ghee',
          'nei': 'ghee',
          'എണ്ണ': 'oil', // Malayalam variant
          'எண்ணெய்': 'oil',
          'ennai': 'oil',
          'அரிசி': 'rice',
          'arisi': 'rice',
          'பருப்பு': 'dal',
          'paruppu': 'dal',
          'சோப்பு': 'soap',
          'soapu': 'soap',
          'டீ': 'tea',
          'தேநீர்': 'tea',
          'காபி': 'coffee',
          'kaapi': 'coffee',
        };

        for (final entry in transliterationMap.entries) {
          if (query.contains(entry.key)) {
            mappedQuery = entry.value;
            break;
          }
        }
      }

      final matchesName = p.name.toLowerCase().contains(mappedQuery);
      final matchesSku = p.sku.toLowerCase().contains(mappedQuery);
      final matchesBarcode = (p.barcode ?? '').contains(mappedQuery);
      return matchesName || matchesSku || matchesBarcode;
    }).toList();

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyStroke,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Wrapped in modern MainLayout App Shell
        body: Column(
          children: [
            // 🏷️ 1. Sub-Header Ribbon (Replacing duplicate legacy AppBar)
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
                        tooltip: 'Back to Dashboard',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Billing Shift',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'REG #01',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Recall Button
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                        onPressed: _showRecallParkedDialog,
                        icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
                        label: const Text('Recall (F9)', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      // Hold Button
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.amber.shade800),
                        onPressed: _parkCurrentCart,
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        label: const Text('Hold Order (F8)', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      // Clear Button
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text('Clear Cart', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      const VerticalDivider(indent: 8, endIndent: 8, width: 1),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'F12: Checkout | F8: Hold | F9: Recall | ESC: Focus Search',
                        child: Icon(Icons.keyboard_rounded, color: Colors.grey.shade500, size: 20),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // 🛍️ 2. Main Split View Workspace
            Expanded(
              child: Row(
                children: [
                  // LEFT PANE: Instant Smart Search & Product Catalog (60%)
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // 🔍 Dual-Language Smart Search Bar
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: _isTamilMode ? 'தேடல்: தயாரிப்பு பெயர் அல்லது பார்கோடு...' : 'Scan barcode or search SKU / product...',
                              prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: AppColors.primary),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Language switch button
                                  TextButton(
                                    onPressed: _toggleLanguage,
                                    child: Text(
                                      _isTamilMode ? 'தமிழ்' : 'ENG',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {}, // Mock voice search trigger
                                    icon: const Icon(Icons.mic_none_rounded, color: Colors.grey),
                                  ),
                                ],
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 📦 Dynamic Product Grid with Low Stock Highlighting
                          Expanded(
                            child: filteredProducts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        Text('No products found matching query', style: TextStyle(color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.35,
                                    ),
                                    itemCount: filteredProducts.length,
                                    itemBuilder: (context, idx) {
                                      final prod = filteredProducts[idx];
                                      final bool isOutOfStock = prod.isOutOfStock;
                                      final bool isLowStock = prod.currentStock > 0 && prod.currentStock < 10;

                                      return Material(
                                        color: isDark ? AppColors.surfaceDark : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: !isOutOfStock
                                              ? () {
                                                  ref.read(cartProvider.notifier).addToCart(prod);
                                                  _searchFocus.requestFocus(); // auto focus restoration
                                                }
                                              : null,
                                          child: Opacity(
                                            opacity: isOutOfStock ? 0.5 : 1.0,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isOutOfStock
                                                      ? AppColors.error.withValues(alpha: 0.4)
                                                      : (isLowStock
                                                          ? Colors.orange.withValues(alpha: 0.5)
                                                          : (isDark ? const Color(0xFF374151) : Colors.grey.shade200)),
                                                  width: (isLowStock || isOutOfStock) ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              prod.name,
                                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          // Smart Stock Badge
                                                          if (isOutOfStock)
                                                            _buildStockBadge('OUT', AppColors.error)
                                                          else if (isLowStock)
                                                            _buildStockBadge('LOW', Colors.orange)
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            isOutOfStock ? 'Unavailable' : 'Stock: ${prod.currentStock} left',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: isOutOfStock
                                                                  ? AppColors.error
                                                                  : (isLowStock ? Colors.orange.shade700 : Colors.grey.shade500),
                                                              fontWeight: isLowStock ? FontWeight.bold : null,
                                                            ),
                                                          ),
                                                          if (shopProfile == ShopCategory.pharmacy) ...[
                                                            Text(
                                                              prod.name.length % 2 == 0 ? 'Exp: Oct 2027' : 'Exp: Nov 2026',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: prod.name.length % 2 == 0 ? Colors.green.shade700 : AppColors.error,
                                                              ),
                                                            ),
                                                          ] else if (shopProfile == ShopCategory.garments) ...[
                                                            const Text(
                                                              'Sizes: M, L',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: AppColors.primary,
                                                              ),
                                                            ),
                                                          ] else if (shopProfile == ShopCategory.bakery) ...[
                                                            const Text(
                                                              'Life: 3 Days',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.orange,
                                                              ),
                                                            ),
                                                          ] else if (shopProfile == ShopCategory.jewellery) ...[
                                                            const Text(
                                                              '22K Gold',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.amber,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        '₹${prod.sellingPrice.toStringAsFixed(2)}',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: AppColors.primary.withValues(alpha: 0.1),
                                                        ),
                                                        child: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                                                      )
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

                  // 🏁 Split Vertical Divider Line
                  VerticalDivider(width: 1, color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),

                  // RIGHT PANE: Active Dynamic Cart Panel (40%)
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.grey.shade50,
                      child: Column(
                        children: [
                          // Cart Top Section & VIP Profile Link
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cart Items Bucket',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${cart.items.length} SKUs',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // VIP Loyalty Ribbon Setup
                                if (cart.selectedCustomer == null)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                    ),
                                    onPressed: _showCustomerSelector,
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                    label: const Text('Link Customer Loyalty Module', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
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
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '⭐ ${cart.selectedCustomer!.loyaltyPoints} PTS',
                                            style: const TextStyle(color: Colors.green, fontSize: 10.5, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.cancel_outlined, size: 18, color: Colors.grey.shade400),
                                          onPressed: () => ref.read(cartProvider.notifier).removeCustomer(),
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
                                        Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text('Register cart is empty.', style: TextStyle(color: Colors.grey.shade500)),
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
                                          color: isDark ? AppColors.surfaceDark : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.product.name,
                                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('₹${item.unitPrice} / unit', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                                                ],
                                              ),
                                            ),
                                            // Incremental controller
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                  onPressed: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                                  onPressed: () => ref.read(cartProvider.notifier).incrementQuantity(item.product.id),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            Text('₹${item.finalTotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Summary calculations & Proceed sticky footer
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              border: Border(
                                top: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                              ),
                            ),
                            child: Column(
                              children: [
                                _ReceiptRow(label: 'Subtotal Base', value: '₹${cart.subtotal.toStringAsFixed(2)}'),
                                const SizedBox(height: 8),
                                _ReceiptRow(label: 'Applied GST (${cart.gstRate}%)', value: '₹${cart.gstAmount.toStringAsFixed(2)}'),
                                const Divider(height: 24),
                                _ReceiptRow(
                                  label: 'NET TOTAL AMOUNT DUE',
                                  value: '₹${cart.netTotal.toStringAsFixed(2)}',
                                  isBold: true,
                                  valueColor: AppColors.primary,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: cart.items.isEmpty ? null : () => _handleCheckout(cart.netTotal),
                                    icon: const Icon(Icons.payments_outlined, size: 22),
                                    label: Text(
                                      'CHECKOUT & COLLECT (F12)',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
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
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 12)),
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
      fontSize: isBold ? 14.5 : 12.5,
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
            fontSize: isBold ? 16.5 : 12.5,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = customers
        .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()) || c.phone.contains(_search))
        .toList();

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isAdding ? 'Register VIP Profile' : 'Link Customer Profile',
            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _isAdding = !_isAdding),
            icon: Icon(_isAdding ? Icons.search : Icons.add),
            label: Text(_isAdding ? 'Lookup' : 'Register'),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                          ref.read(customersListProvider.notifier).registerCustomer(
                                _nameController.text,
                                _phoneController.text,
                                _emailController.text,
                              );
                          final latestCustomers = ref.read(customersListProvider);
                          ref.read(cartProvider.notifier).selectCustomer(latestCustomers.last);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⭐ VIP Customer registered with 10 welcome points!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Enroll & Link to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      hintText: 'Search by phone number or name...',
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
                            child: Text('No matching profiles found.'),
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
                                  backgroundColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
                                  child: Text(cust.name.substring(0, 1), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(cust.phone, style: const TextStyle(fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${cust.loyaltyPoints} pts',
                                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
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
