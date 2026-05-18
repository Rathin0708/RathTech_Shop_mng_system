import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/local_db/models/bill_model.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/sales_providers.dart';
import '../../../../core/providers/onboarding_provider.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  void _viewReceiptDetail(BuildContext context, BillModel bill) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Invoice Receipt: ${bill.invoiceNumber}',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Issued At:', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                  Text(
                    DateFormat('MMM d, y HH:mm').format(bill.timestamp),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settlement Mode:', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bill.paymentMethod.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11.5),
                    ),
                  )
                ],
              ),
              const Divider(height: 32),
              Text(
                'PURCHASED LINE ITEMS',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),

              // Dynamic list of nested embedded items
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: bill.purchasedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = bill.purchasedItems[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName}  x${item.quantity}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '₹${item.lineTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Applied GST Tax', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  Text('₹${bill.gstAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NET AMOUNT PAID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                  Text(
                    '₹${bill.netTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close Viewer')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🖨️ Re-dispatching reprint command to thermal register...'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Reprint Ticket'),
          )
        ],
      ),
    );
  }

  Future<void> _exportToExcelCSV(BuildContext context, WidgetRef ref, List<BillModel> bills) async {
    try {
      if (bills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active invoices to export.'), backgroundColor: AppColors.error),
        );
        return;
      }

      final csvBuffer = StringBuffer();
      // CSV Header metadata
      csvBuffer.writeln('RathTech Shop Management POS - Daily Sales Ledger');
      csvBuffer.writeln('Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      csvBuffer.writeln('Total Invoices: ${bills.length}');
      csvBuffer.writeln('Gross collections: INR ${bills.fold(0.0, (sum, b) => sum + b.netTotal).toStringAsFixed(2)}');
      csvBuffer.writeln();
      
      // Table Columns
      csvBuffer.writeln('Invoice Number,Date/Time,Payment Method,Items Count,Subtotal (INR),GST Tax (INR),Net Total (INR),Cloud Synced');

      // Table Rows
      for (final bill in bills) {
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(bill.timestamp);
        final syncedStr = bill.isSyncedToCloud ? 'YES' : 'NO';
        csvBuffer.writeln(
          '${bill.invoiceNumber},"$formattedDate",${bill.paymentMethod},${bill.purchasedItems.length},${bill.subtotal.toStringAsFixed(2)},${bill.gstAmount.toStringAsFixed(2)},${bill.netTotal.toStringAsFixed(2)},$syncedStr'
        );
      }

      // Ensure reports directory exists
      final reportsDir = Directory('d:\\rath_tech_projects\\RathTech_Shop_mng_system\\User Portal\\reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final timestampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${reportsDir.path}\\sales_report_$timestampStr.csv';
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());
      
      ref.read(onboardingProvider.notifier).completeStep('pdfExported');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📊 CSV Excel ledger exported to reports folder!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open Excel',
            textColor: Colors.white,
            onPressed: () {
              Process.run('cmd', ['/c', 'start', '""', filePath]);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _exportToVisualPDF(BuildContext context, WidgetRef ref, List<BillModel> bills) async {
    try {
      if (bills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active invoices to export.'), backgroundColor: AppColors.error),
        );
        return;
      }

      final totalSales = bills.fold(0.0, (sum, b) => sum + b.netTotal);
      final averageSpent = bills.isEmpty ? 0.0 : totalSales / bills.length;
      final unsynced = bills.where((b) => !b.isSyncedToCloud).length;

      final htmlBuffer = StringBuffer();
      htmlBuffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>RathTech POS - Daily Sales Ledger Summary</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f3f4f6;
      color: #111827;
      margin: 0;
      padding: 40px;
    }
    .container {
      max-width: 1000px;
      margin: 0 auto;
      background: #ffffff;
      padding: 40px;
      border-radius: 16px;
      box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #e5e7eb;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      color: #4F46E5;
      font-weight: 800;
    }
    .header p {
      margin: 5px 0 0 0;
      color: #6B7280;
      font-size: 13px;
    }
    .kpis {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      margin-bottom: 30px;
    }
    .kpi-card {
      background: #f9fafb;
      border: 1px solid #e5e7eb;
      border-radius: 12px;
      padding: 20px;
      text-align: center;
    }
    .kpi-title {
      font-size: 11px;
      font-weight: 700;
      color: #6B7280;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }
    .kpi-value {
      font-size: 20px;
      font-weight: 800;
      color: #111827;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 30px;
    }
    th, td {
      padding: 14px 16px;
      text-align: left;
      border-bottom: 1px solid #e5e7eb;
      font-size: 13.5px;
    }
    th {
      background-color: #f9fafb;
      color: #374151;
      font-weight: 700;
    }
    tr:hover {
      background-color: #f9fafb;
    }
    .badge {
      display: inline-block;
      padding: 3px 8px;
      font-size: 10.5px;
      font-weight: 700;
      border-radius: 4px;
    }
    .badge-cash { background-color: #e0f2fe; color: #0369a1; }
    .badge-upi { background-color: #ecfdf5; color: #047857; }
    .badge-card { background-color: #f3e8ff; color: #6b21a8; }
    
    .badge-synced { background-color: #d1fae5; color: #065f46; }
    .badge-pending { background-color: #ffedd5; color: #9a3412; }
    
    .btn-print {
      background-color: #4F46E5;
      color: white;
      border: none;
      padding: 12px 24px;
      font-size: 14px;
      font-weight: 700;
      border-radius: 8px;
      cursor: pointer;
      box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.4);
    }
    .btn-print:hover {
      background-color: #4338ca;
    }
    @media print {
      body { background-color: white; padding: 0; }
      .container { box-shadow: none; padding: 0; }
      .btn-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div>
        <h1>Daily Sales Ledger Summary</h1>
        <p>RathTech POS • Main Store Branch • Terminal #01</p>
      </div>
      <div>
        <button class="btn-print" onclick="window.print()">Print Ledger Document</button>
      </div>
    </div>
    
    <div class="kpis">
      <div class="kpi-card">
        <div class="kpi-title">Gross collections</div>
        <div class="kpi-value">₹${totalSales.toStringAsFixed(2)}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">Invoices generated</div>
        <div class="kpi-value">${bills.length} bills</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">Average Invoice Value</div>
        <div class="kpi-value">₹${averageSpent.toStringAsFixed(2)}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">Pending Cloud Sync</div>
        <div class="kpi-value" style="color: ${unsynced > 0 ? '#ea580c' : '#10b981'}">$unsynced records</div>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th>Invoice Number</th>
          <th>Date / Time</th>
          <th>Payment Mode</th>
          <th>Items Count</th>
          <th>GST Tax</th>
          <th>Net Amount</th>
          <th>Sync Status</th>
        </tr>
      </thead>
      <tbody>
''');

      for (final bill in bills) {
        final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(bill.timestamp);
        final methodClass = 'badge-${bill.paymentMethod.toLowerCase()}';
        final syncClass = bill.isSyncedToCloud ? 'badge-synced' : 'badge-pending';
        final syncText = bill.isSyncedToCloud ? 'Synced' : 'Pending';

        htmlBuffer.writeln('''
        <tr>
          <td style="font-weight: 700;">${bill.invoiceNumber}</td>
          <td>$formattedDate</td>
          <td><span class="badge $methodClass">${bill.paymentMethod.toUpperCase()}</span></td>
          <td>${bill.purchasedItems.length} items</td>
          <td>₹${bill.gstAmount.toStringAsFixed(2)}</td>
          <td style="font-weight: 700; color: #10b981;">₹${bill.netTotal.toStringAsFixed(2)}</td>
          <td><span class="badge $syncClass">$syncText</span></td>
        </tr>
''');
      }

      htmlBuffer.writeln('''
      </tbody>
    </table>
    
    <div style="text-align: center; color: #9ca3af; font-size: 12px; margin-top: 50px; border-top: 1px dashed #e5e7eb; padding-top: 20px;">
      Document generated locally by RathTech SaaS. Copyright © 2026 RathTech Retails. All rights reserved.
    </div>
  </div>
</body>
</html>
''');

      // Ensure reports directory exists
      final reportsDir = Directory('d:\\rath_tech_projects\\RathTech_Shop_mng_system\\User Portal\\reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final timestampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${reportsDir.path}\\sales_ledger_document_$timestampStr.html';
      final file = File(filePath);
      await file.writeAsString(htmlBuffer.toString());

      ref.read(onboardingProvider.notifier).completeStep('pdfExported');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📄 Visual PDF Invoice Ledger Document compiled successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open Report',
            textColor: Colors.white,
            onPressed: () {
              Process.run('cmd', ['/c', 'start', '""', filePath]);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to compile PDF document: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bills = salesAsync.value ?? [];
 
    return Scaffold(
      backgroundColor: Colors.transparent, // Delegate to MainLayout
      body: Column(
        children: [
          // 🏷️ 1. Clean Top Header replacing AppBar
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
                      tooltip: 'Return',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Local Sales Ledger',
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
                    if (bills.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => _exportToExcelCSV(context, ref, bills),
                        icon: const Icon(Icons.table_view_rounded, size: 18, color: Colors.green),
                        label: const Text('Export Excel (CSV)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _exportToVisualPDF(context, ref, bills),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.red),
                        label: const Text('Export Visual PDF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(salesHistoryProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh Ledger'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📊 2. Main Content Body
          Expanded(
            child: salesAsync.when(
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
                          'No active transactions logged.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invoices completed during active shifts will display here.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                // Analytics Logic
                final double totalSales = bills.fold(0.0, (sum, b) => sum + b.netTotal);
                final int unsyncedCount = bills.where((b) => !b.isSyncedToCloud).length;

                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Interactive Analytics Boxes
                      Row(
                        children: [
                          _SummaryBox(
                            title: 'Gross Shift Collections',
                            value: '₹${totalSales.toStringAsFixed(2)}',
                            icon: Icons.payments_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 20),
                          _SummaryBox(
                            title: 'Total Invoices Generated',
                            value: '${bills.length} bills',
                            icon: Icons.description_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 20),
                          _SummaryBox(
                            title: 'Pending Cloud Synchronization',
                            value: '$unsyncedCount records',
                            icon: Icons.cloud_sync_rounded,
                            color: unsyncedCount > 0 ? Colors.orange.shade700 : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'CHRONOLOGICAL INVOICE TRAIL',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Interactive Ledger List
                      Expanded(
                        child: ListView.separated(
                          itemCount: bills.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bill = bills[index];
                            final isSynced = bill.isSyncedToCloud;

                            return InkWell(
                              onTap: () => _viewReceiptDetail(context, bill),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Details Section
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bill.invoiceNumber,
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  bill.paymentMethod.toUpperCase(),
                                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                DateFormat('HH:mm a • MMM dd').format(bill.timestamp),
                                                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Metric Summary
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${bill.purchasedItems.length} line items',
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                    ),

                                    // Cloud Status Pill
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSynced ? Icons.cloud_done_rounded : Icons.sync_problem_rounded,
                                            size: 16,
                                            color: isSynced ? Colors.green : Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isSynced ? 'Backed Up' : 'Pending Sync',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: isSynced ? Colors.green : Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Financial Amount
                                    Row(
                                      children: [
                                        Text(
                                          '₹${bill.netTotal.toStringAsFixed(2)}',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
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
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
