import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Packages',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure public pricing matrices, active feature flags, and device limitations.',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Tier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 2. Premium Plan Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 3 : 1,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: isWide ? 0.72 : 1.5,
                  children: const [
                    _PricingCard(
                      title: 'Retail Starter',
                      price: '₹999',
                      period: '/ month',
                      description: 'Essential offline-first billing for independent corner shops.',
                      features: [
                        'Max 1 POS Register Device',
                        'Unlimited Offline Billing',
                        'Local Inventory Caching',
                        'End-of-Day Mini Reports',
                        'Standard Email Support',
                      ],
                      isPopular: false,
                    ),
                    _PricingCard(
                      title: 'Business Pro',
                      price: '₹2,499',
                      period: '/ month',
                      description: 'Advanced inventory tracking and real-time multi-terminal sync.',
                      features: [
                        'Up to 3 Register Devices',
                        'Real-time Cloud Sync Engine',
                        'Low-Stock Predictive Alerts',
                        'Comprehensive PDF Invoices',
                        'Priority Chat Support',
                        'Customer Loyalty Database',
                      ],
                      isPopular: true, // "Most Popular" highlight
                    ),
                    _PricingCard(
                      title: 'Enterprise Fleet',
                      price: '₹5,999',
                      period: '/ month',
                      description: 'Full multi-branch control center and custom API integrations.',
                      features: [
                        'Unlimited Register Devices',
                        'Unlimited Shop Branches',
                        'Centralized Inventory Transfer',
                        'Multi-Admin Analytics Suite',
                        '24/7 Phone Assistance',
                        'Dedicated Customer Manager',
                      ],
                      isPopular: false,
                    ),
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool isPopular;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isPopular 
            ? (isDark ? AppColors.primaryDark.withOpacity(0.2) : AppColors.primary.withOpacity(0.02))
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular 
              ? AppColors.primary 
              : (isDark ? const Color(0xFF374151) : Colors.grey.shade200),
          width: isPopular ? 2.5 : 1.5,
        ),
        boxShadow: isPopular ? [
          BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular Badge Overlay
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.only(bottom: 16),
              child: const Text(
                'MOST RECOMMENDED',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
              ),
            ),
          
          Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(period, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                return Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        features[idx],
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isPopular ? AppColors.primary : Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: isPopular ? AppColors.primary : null,
                backgroundColor: isPopular ? AppColors.primary.withOpacity(0.05) : null,
              ),
              child: const Text('Edit Plan Structure', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
