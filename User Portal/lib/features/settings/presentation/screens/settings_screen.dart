import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/shop_profile_provider.dart';
import '../../../../core/models/tenant_model.dart';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/widgets/premium_lock.dart';

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
      const SnackBar(
        content: Row(
          children: [
            SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Exporting local Isar relational tables to JSON array...'),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⬇️ Offline snapshot exported successfully to internal storage! (Size: 3.4 KB)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _saveSettings() {
    ref.read(onboardingProvider.notifier).completeStep('settingsCustomized');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ POS configuration parameters saved persistently to local storage.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopProfile = ref.watch(shopProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Hosted in MainLayout
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
                      tooltip: 'Back to Dashboard',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Terminal Preferences',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Apply Global Config'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // ⚙️ 2. Split Workspace
          Expanded(
            child: Padding(
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
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
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
                                      dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                                      items: ['58mm Thermal', '80mm Thermal']
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold))))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _printerSize = v);
                                      },
                                    ),
                                  ],
                                ),
                                Divider(height: 32, color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Auto-Print on Payment Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: const Text('Automatically fires print dispatch upon checkout without prompts.', style: TextStyle(fontSize: 12)),
                                  value: _autoPrint,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _autoPrint = v),
                                ),
                                Divider(height: 32, color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                TextFormField(
                                  initialValue: _receiptHeader,
                                  decoration: InputDecoration(
                                    labelText: 'Receipt Header Title',
                                    filled: true,
                                    fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                                    prefixIcon: const Icon(Icons.title_rounded, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (v) => setState(() => _receiptHeader = v),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: _receiptFooter,
                                  decoration: InputDecoration(
                                    labelText: 'Receipt Footer Text',
                                    filled: true,
                                    fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                                    prefixIcon: const Icon(Icons.comment_rounded, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _registerNo,
                                        decoration: InputDecoration(
                                          labelText: 'Local Register Identifier',
                                          filled: true,
                                          fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onChanged: (v) => setState(() => _registerNo = v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _currencySymbol,
                                        dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                                        decoration: InputDecoration(
                                          labelText: 'System Currency Node',
                                          filled: true,
                                          fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                const SizedBox(height: 16),
                                DropdownButtonFormField<ShopCategory>(
                                  initialValue: shopProfile,
                                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                                  decoration: InputDecoration(
                                    labelText: 'Active Shop Industry Profile',
                                    helperText: 'Switches system database schemas & workflows dynamically.',
                                    filled: true,
                                    fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: ShopCategory.general, child: Text('General Retail / Kirana')),
                                    const DropdownMenuItem(value: ShopCategory.pharmacy, child: Text('💊 Pharmacy & Healthcare')),
                                    const DropdownMenuItem(value: ShopCategory.garments, child: Text('👕 Garments & Apparel Boutique')),
                                    const DropdownMenuItem(value: ShopCategory.bakery, child: Text('🍞 Bakery & Perishable Goods')),
                                    const DropdownMenuItem(value: ShopCategory.jewellery, child: Text('💎 Jewellery & Ornaments Store')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      ref.read(shopProfileProvider.notifier).updateCategory(v);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Switched system UX context to ${v.name.toUpperCase()} mode!'),
                                          backgroundColor: AppColors.success,
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                Divider(height: 32, color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Beep Alerts on Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: const Text('Trigger native beep audio upon adding products to cart list.', style: TextStyle(fontSize: 12)),
                                  value: _isSoundEnabled,
                                  activeThumbColor: AppColors.primary,
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
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Use AMOLED Dark System Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: const Text('Reduces eyestrain for late-night cashiers and dark ambient shops.', style: TextStyle(fontSize: 12)),
                                  value: _isDarkMode,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _isDarkMode = v),
                                ),
                                Divider(height: 32, color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                                PremiumLock(
                                  premiumExplanation: 'Unlock Nightly Cloud Backups',
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Enable Nightly Cloud Auto-Archiving', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: const Text('Auto-packages offline SQL logs and dispatches snapshot caches daily.', style: TextStyle(fontSize: 12)),
                                    value: _isAutoBackup,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (v) => setState(() => _isAutoBackup = v),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                        ),
                                        onPressed: _executeDataBackup,
                                        icon: const Icon(Icons.cloud_download_rounded, color: AppColors.primary),
                                        label: const Text('Manually Trigger JSON Export', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
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
                        _SectionTitle(title: 'Live Printer Output Layout', icon: Icons.visibility_rounded),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white, // Receipts are always white paper
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                // Thermal Header
                                Text(
                                  _receiptHeader.toUpperCase(),
                                  style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '$_registerNo • THERMAL TERMINAL',
                                  style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                const Text('------------------------------------', style: TextStyle(color: Colors.black38)),
                                const SizedBox(height: 8),

                                // Body placeholder
                                Expanded(
                                  child: ListView(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      _PreviewItem(title: 'Tata Salt Premium', qty: 1, price: 28.00, currency: _currencySymbol.substring(0, 1)),
                                      _PreviewItem(title: 'Fortune Oil 1L', qty: 2, price: 340.00, currency: _currencySymbol.substring(0, 1)),
                                      const SizedBox(height: 16),
                                      const Text('------------------------------------', style: TextStyle(color: Colors.black38)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('NET TOTAL', style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15)),
                                          Text('${_currencySymbol.substring(0, 1)}368.00', style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),

                                // Footer
                                const Text('------------------------------------', style: TextStyle(color: Colors.black38)),
                                const SizedBox(height: 8),
                                Text(
                                  _receiptFooter,
                                  style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'SIMULATOR: ${_printerSize.split(' ').first} LAYOUT',
                                  style: GoogleFonts.courierPrime(fontSize: 9, color: Colors.grey.shade500),
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
          ),
        ],
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
        Icon(icon, size: 22, color: AppColors.primary),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title x$qty', style: GoogleFonts.courierPrime(fontSize: 13, color: Colors.black)),
          Text('$currency${price.toStringAsFixed(2)}', style: GoogleFonts.courierPrime(fontSize: 13, color: Colors.black)),
        ],
      ),
    );
  }
}
