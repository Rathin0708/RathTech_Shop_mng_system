import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/cash_providers.dart';

class CashDrawerScreen extends ConsumerStatefulWidget {
  const CashDrawerScreen({super.key});

  @override
  ConsumerState<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends ConsumerState<CashDrawerScreen> {
  
  void _showActionDialog(String type) {
    final isDrop = type == 'Drop';
    final label = isDrop ? 'Safe Cash Drop' : 'Vendor Petty Payout';
    final reasonController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isDrop ? 'Reference / Bags Number' : 'Expense Description',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isDrop ? AppColors.primary : AppColors.error),
            onPressed: () {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt > 0 && reasonController.text.isNotEmpty) {
                ref.read(cashDrawerProvider.notifier).logCashAction(reasonController.text, amt, type);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('💸 Cash ledger successfully logged: ₹$amt'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Post Transaction', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _endShiftWizard(double expected) {
    final countController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Cash Register Lane', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your physical total counted cash from the physical tray.', style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 20),
              TextFormField(
                controller: countController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Physical Cash Found (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calculate)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ledger Expects:', style: TextStyle(fontSize: 12)),
                    Text('₹${expected.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              final actual = double.tryParse(countController.text) ?? 0.0;
              final diff = actual - expected;
              Navigator.pop(context);

              // Shift Result Screen overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('Shift Variance Report', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        diff.abs() < 0.01 ? Icons.check_circle_rounded : (diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                        size: 48,
                        color: diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.orange : Colors.red),
                      ),
                      const SizedBox(height: 16),
                      const Text('SHIFT BALANCING RESULTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        diff.abs() < 0.01 ? 'BALANCED PERFECTLY' : (diff > 0 ? 'OVERAGE DETECTED' : 'SHORTAGE DETECTED'),
                        style: TextStyle(fontWeight: FontWeight.bold, color: diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.orange : Colors.red)),
                      ),
                      const SizedBox(height: 20),
                      _StatRow(label: 'Expected Cash', value: '₹${expected.toStringAsFixed(2)}'),
                      _StatRow(label: 'Counted Cash', value: '₹${actual.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('NET VARIANCE', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${diff >= 0 ? '+' : ''}₹${diff.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.orange : Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                      onPressed: () {
                        ref.read(cashDrawerProvider.notifier).resetDrawer(5000.0); // Reset to next shift base float ₹5000
                        Navigator.pop(context);
                        context.go(RouteNames.dashboard);
                      },
                      child: const Text('Print Close Sheet & Reset Lane'),
                    )
                  ],
                ),
              );
            },
            child: const Text('Verify Ledger Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashState = ref.watch(cashDrawerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text(
          'Cash Drawer Management',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Metrics and Action Bar (65%)
            Expanded(
              flex: 65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big Focus Card: Expected Cash
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPECTED DRAWER CASH ON HAND',
                              style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${cashState.expectedCash.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error.withOpacity(0.2),
                            foregroundColor: Colors.red.shade100,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _endShiftWizard(cashState.expectedCash),
                          icon: const Icon(Icons.lock_clock_rounded, size: 18),
                          label: const Text('END ACTIVE SHIFT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sub Metrics Grid
                  Row(
                    children: [
                      _MetricMiniCard(label: 'Base Opening Float', value: '₹${cashState.openingFloat.toStringAsFixed(2)}', color: Colors.grey),
                      const SizedBox(width: 16),
                      _MetricMiniCard(label: 'Shift Cash Sales (+)', value: '₹${cashState.cashSales.toStringAsFixed(2)}', color: Colors.green),
                      const SizedBox(width: 16),
                      _MetricMiniCard(label: 'Petty Payouts & Drops (-)', value: '₹${cashState.totalOut.toStringAsFixed(2)}', color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Ledger Action Block
                  Text(
                            'LEDGER POSTINGS',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () => _showActionDialog('Drop'),
                          icon: const Icon(Icons.savings_rounded, color: AppColors.primary),
                          label: const Text('Safe Cash Drop (Deposit)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () => _showActionDialog('Payout'),
                          icon: const Icon(Icons.shopping_bag_rounded, color: Colors.red),
                          label: const Text('Petty Vendor Payout (Withdraw)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 32),

            // Right Column: Journal Timeline (35%)
            Expanded(
              flex: 35,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SHIFT JOURNAL LOGS', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 20),
                    
                    Expanded(
                      child: cashState.journal.isEmpty
                          ? const Center(child: Text('No adjustments made in this shift.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.separated(
                              itemCount: cashState.journal.length,
                              separatorBuilder: (_, __) => const Divider(height: 24),
                              itemBuilder: (context, idx) {
                                final log = cashState.journal[idx];
                                final isOut = log.type != 'Add';
                                
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isOut ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      child: Icon(isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14, color: isOut ? Colors.red : Colors.green),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(log.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(DateFormat('hh:mm a').format(log.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isOut ? '-' : '+'}₹${log.amount.toStringAsFixed(0)}',
                                      style: TextStyle(fontWeight: FontWeight.w900, color: isOut ? Colors.red : Colors.green),
                                    )
                                  ],
                                );
                              },
                            ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricMiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color == Colors.grey ? null : color)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
