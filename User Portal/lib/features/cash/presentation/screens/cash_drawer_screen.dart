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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(label, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: isDrop ? 'Reference / Bag Tag Number' : 'Expense Description / Vendor',
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDrop ? AppColors.primary : AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt > 0 && reasonController.text.isNotEmpty) {
                  ref.read(cashDrawerProvider.notifier).logCashAction(reasonController.text, amt, type);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('💸 Cash ledger successfully logged: ₹$amt'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Post Transaction'),
            )
          ],
        );
      },
    );
  }

  void _endShiftWizard(double expected) {
    final countController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Close Register Lane', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please enter the total physical cash counted from the drawer tray.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: countController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Physical Cash Total (₹)',
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.calculate),
                  ),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ledger Expects:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('₹${expected.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final actual = double.tryParse(countController.text) ?? 0.0;
                final diff = actual - expected;
                Navigator.pop(context);

                // Shift Result Screen overlay
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Shift Balancing Result', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: diff.abs() < 0.01 ? Colors.green.withValues(alpha: 0.1) : (diff > 0 ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            diff.abs() < 0.01 ? Icons.check_circle_rounded : (diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                            size: 48,
                            color: diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.orange.shade700 : Colors.red),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          diff.abs() < 0.01 ? 'BALANCED PERFECTLY' : (diff > 0 ? 'OVERAGE DETECTED' : 'SHORTAGE DETECTED'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.orange.shade700 : Colors.red),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _StatRow(label: 'Expected Ledger Cash', value: '₹${expected.toStringAsFixed(2)}'),
                              _StatRow(label: 'Physical Counted Cash', value: '₹${actual.toStringAsFixed(2)}'),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('NET VARIANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    '${diff >= 0 ? '+' : ''}₹${diff.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.orange.shade700 : Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    actions: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(cashDrawerProvider.notifier).resetDrawer(5000.0); // Next shift float ₹5000
                          Navigator.pop(context);
                          context.go(RouteNames.dashboard);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🖨️ Shift closing X-report dispatched to printer.'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Print Close Sheet & Reset Lane', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              },
              child: const Text('Verify Count'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashState = ref.watch(cashDrawerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by MainLayout
      body: Column(
        children: [
          // 🏷️ 1. Sub-Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go(RouteNames.dashboard),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cash Register Float Management',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),

          // 💰 2. Main Workspace
          Expanded(
            child: Padding(
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'EXPECTED DRAWER CASH (INR)',
                                        style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '₹${cashState.expectedCash.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error.withValues(alpha: 0.15),
                                  foregroundColor: Colors.red.shade200,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _endShiftWizard(cashState.expectedCash),
                                icon: const Icon(Icons.lock_clock_rounded, size: 18),
                                label: const Text('END SHIFT & CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sub Metrics Grid
                        Row(
                          children: [
                            _MetricMiniCard(label: 'Opening Base Float', value: '₹${cashState.openingFloat.toStringAsFixed(2)}', color: Colors.grey.shade500),
                            const SizedBox(width: 16),
                            _MetricMiniCard(label: 'Shift Cash Sales (+)', value: '₹${cashState.cashSales.toStringAsFixed(2)}', color: AppColors.success),
                            const SizedBox(width: 16),
                            _MetricMiniCard(label: 'Payouts / Drops (-)', value: '₹${cashState.totalOut.toStringAsFixed(2)}', color: AppColors.error),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Ledger Action Block
                        Text(
                          'POST MANUAL LEDGER ENTRY',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),

                        // Action buttons row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                onPressed: () => _showActionDialog('Drop'),
                                icon: const Icon(Icons.savings_outlined, color: AppColors.primary),
                                label: const Text('Safe Cash Drop (Deposit)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                onPressed: () => _showActionDialog('Payout'),
                                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.error),
                                label: const Text('Vendor Payout (Withdraw)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14)),
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
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHIFT PETTY CASH LOGS',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 24),

                          Expanded(
                            child: cashState.journal.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                                        const SizedBox(height: 12),
                                        Text('No cash adjustments logged.', style: TextStyle(color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: cashState.journal.length,
                                    separatorBuilder: (_, __) => const Divider(height: 28),
                                    itemBuilder: (context, idx) {
                                      final log = cashState.journal[idx];
                                      final isOut = log.type != 'Add';

                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isOut ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                              size: 16,
                                              color: isOut ? AppColors.error : AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  log.reason,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('hh:mm a').format(log.timestamp),
                                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isOut ? '-' : '+'}₹${log.amount.toStringAsFixed(2)}',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isOut ? AppColors.error : AppColors.success,
                                            ),
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
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color == Colors.grey.shade500 ? (isDark ? Colors.white : Colors.black) : color,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
