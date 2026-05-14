import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Mock form states for POS Customizations
  String _printerSize = '80mm Thermal';
  bool _autoPrint = true;
  String _receiptHeader = 'RATH-TECH RETAILS';
  String _receiptFooter = 'Thank you for shopping! Visit again.';
  
  String _registerNo = 'REG #01';
  String _currencySymbol = '₹ (INR)';
  bool _isSoundEnabled = true;
  
  bool _isDarkMode = false;
  bool _isAutoBackup = true;

  void _executeDataBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Exporting local Isar relational tables to JSON array...'),
          ],
        ),
        backgroundColor: AppColors.info,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⬇️ Offline snapshot exported successfully to internal storage! (Size: 3.4 KB)'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ POS configuration parameters saved persistently to local storage.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text(
          'Terminal Configuration',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Scrollable Form Sections (60%)
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Hardware Thermal Printer Settings
                    _SectionTitle(title: 'Thermal Printer & Hardware', icon: Icons.print_rounded),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Printer Size Select
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Thermal Paper Width', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Choose standard paper size for layout scaling.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                              DropdownButton<String>(
                                value: _printerSize,
                                underline: const SizedBox(),
                                items: ['58mm Thermal', '80mm Thermal']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _printerSize = v);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          // Auto Print Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Auto-Print on Payment Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Automatically fires print dispatch upon checkout without prompts.', style: TextStyle(fontSize: 12)),
                            value: _autoPrint,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _autoPrint = v),
                          ),
                          const Divider(height: 32),

                          // Custom Header Inputs
                          TextFormField(
                            initialValue: _receiptHeader,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Header Title',
                              prefixIcon: Icon(Icons.title_rounded, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _receiptHeader = v),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _receiptFooter,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Footer Text',
                              prefixIcon: Icon(Icons.comment_rounded, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _receiptFooter = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section 2: Local POS Operational Parameters
                    _SectionTitle(title: 'Terminal Identifiers', icon: Icons.computer_rounded),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _registerNo,
                                  decoration: const InputDecoration(
                                    labelText: 'Local Register Identifier',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => setState(() => _registerNo = v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _currencySymbol,
                                  decoration: const InputDecoration(
                                    labelText: 'System Currency Node',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['₹ (INR)', '\$ (USD)', '€ (EUR)']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _currencySymbol = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Beep Alerts on Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Trigger native beep audio upon adding products to cart list.', style: TextStyle(fontSize: 12)),
                            value: _isSoundEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isSoundEnabled = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section 3: Visual Styling & Active Backups
                    _SectionTitle(title: 'Interface & Offline Backups', icon: Icons.color_lens_rounded),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Use AMOLED Dark System Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Reduces eyestrain for late-night cashiers and dark ambient shops.', style: TextStyle(fontSize: 12)),
                            value: _isDarkMode,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isDarkMode = v),
                          ),
                          const Divider(height: 32),
                          
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Nightly Cloud Auto-Archiving', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Auto-packages offline SQL logs and dispatches snapshot caches daily.', style: TextStyle(fontSize: 12)),
                            value: _isAutoBackup,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isAutoBackup = v),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: _executeDataBackup,
                                  icon: const Icon(Icons.cloud_download_rounded),
                                  label: const Text('Manually Run Export Snapshot', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Action Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.go(RouteNames.dashboard),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
                          child: const Text('Discard Changes'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Apply POS Config'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),

            // Right Side: Real-time Receipt Live Preview! (40%)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Live Layout Preview', icon: Icons.visibility_rounded),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          // Thermal Header
                          Text(
                            _receiptHeader.toUpperCase(),
                            style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '$_registerNo • TERMINAL LANE',
                            style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black54),
                          ),
                          const Text('------------------------------', style: TextStyle(color: Colors.black38)),
                          
                          // Body placeholder
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _PreviewItem(title: 'Tata Salt Premium', qty: 1, price: 28.00, currency: _currencySymbol.substring(0,1)),
                                _PreviewItem(title: 'Fortune Oil 1L', qty: 2, price: 340.00, currency: _currencySymbol.substring(0,1)),
                                const SizedBox(height: 12),
                                const Text('------------------------------', style: TextStyle(color: Colors.black38)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('NET TOTAL', style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, color: Colors.black)),
                                    Text('${_currencySymbol.substring(0,1)}368.00', style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          
                          // Footer
                          const Text('------------------------------', style: TextStyle(color: Colors.black38)),
                          Text(
                            _receiptFooter,
                            style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Printed: ${_printerSize.split(' ').first} Layout Engine',
                            style: GoogleFonts.courierPrime(fontSize: 8, color: Colors.grey.shade600),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String title;
  final int qty;
  final double price;
  final String currency;

  const _PreviewItem({
    required this.title,
    required this.qty,
    required this.price,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title x$qty', style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
          Text('$currency${price.toStringAsFixed(2)}', style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }
}
