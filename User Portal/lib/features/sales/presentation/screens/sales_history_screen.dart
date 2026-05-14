import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/local_db/models/bill_model.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/sales_providers.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  void _viewReceiptDetail(BuildContext context, BillModel bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice Details: ${bill.invoiceNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Issued:', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Text(DateFormat('MMM d, y HH:mm').format(bill.timestamp), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Method:', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Text(bill.paymentMethod.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                ],
              ),
              const Divider(height: 24),
              
              const Text('PURCHASED ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              
              // Dynamic list of nested embedded items
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: bill.purchasedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = bill.purchasedItems[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} x${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    );
                  },
                ),
              ),
              
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GST Tax Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('₹${bill.gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NET TOTAL PAID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('₹${bill.netTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🖨️ Re-dispatching reprint command to thermal head...'), backgroundColor: AppColors.success),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Reprint Ticket'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text(
          'Local Sales Audits',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(salesHistoryProvider),
            tooltip: 'Reload Ledger',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load local archives: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No local transactions found.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invoices completed during active shifts will serialize here.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // --- Compute Analytics ---
          final double totalSales = bills.fold(0.0, (sum, b) => sum + b.netTotal);
          final int unsyncedCount = bills.where((b) => !b.isSyncedToCloud).length;

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Analytical Overview Row
                Row(
                  children: [
                    _SummaryBox(
                      title: 'Shift Collections',
                      value: '₹${totalSales.toStringAsFixed(2)}',
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 20),
                    _SummaryBox(
                      title: 'Invoices Generated',
                      value: '${bills.length} bills',
                      icon: Icons.description_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 20),
                    _SummaryBox(
                      title: 'Awaiting Cloud Backup',
                      value: '$unsyncedCount records',
                      icon: Icons.cloud_sync_rounded,
                      color: unsyncedCount > 0 ? Colors.orange : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Search / Sort Label
                Text(
                  'RECENT CHRONOLOGICAL LEDGER',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. The Interactive Audit List
                Expanded(
                  child: ListView.separated(
                    itemCount: bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final isSynced = bill.isSyncedToCloud;

                      return InkWell(
                        onTap: () => _viewReceiptDetail(context, bill),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF374151)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Column 1: Invoice and Method
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bill.invoiceNumber,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            bill.paymentMethod.toUpperCase(),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('HH:mm a • MMM dd').format(bill.timestamp),
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Column 2: Items count summary
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${bill.purchasedItems.length} items',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),

                              // Column 3: Cloud sync status
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSynced ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                                      size: 14,
                                      color: isSynced ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSynced ? 'Backed Up' : 'Pending Sync',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSynced ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Column 4: Pricing Total and action icon
                              Row(
                                children: [
                                  Text(
                                    '₹${bill.netTotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
