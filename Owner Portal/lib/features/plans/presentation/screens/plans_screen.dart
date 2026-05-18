import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/plan_model.dart';
import '../providers/plan_providers.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  
  void _showAddOrEditPlanDialog({PlanModel? existingPlan}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existingPlan != null;

    String title = existingPlan?.title ?? '';
    String description = existingPlan?.description ?? '';
    String price = existingPlan?.price ?? '';
    String period = existingPlan?.period ?? '/ month';
    int maxDevices = existingPlan?.maxDevices ?? 1;
    int maxBranches = existingPlan?.maxBranches ?? 1;
    bool isPopular = existingPlan?.isPopular ?? false;
    
    // Convert features list to a single comma-separated string for editing
    final featuresController = TextEditingController(
      text: existingPlan?.features.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              title: Text(
                isEditing ? 'Configure Subscription Tier' : 'Onboard New Subscription Tier',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: title,
                          decoration: const InputDecoration(
                            labelText: 'Tier Name',
                            hintText: 'e.g. Retail Premium Plus',
                          ),
                          onChanged: (v) => title = v,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: description,
                          decoration: const InputDecoration(
                            labelText: 'Tier Teaser Description',
                            hintText: 'e.g. Best for global bakeries and high volume registers.',
                          ),
                          maxLines: 2,
                          onChanged: (v) => description = v,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: price,
                                decoration: const InputDecoration(
                                  labelText: 'Monthly Price Label',
                                  hintText: 'e.g. ₹3,499',
                                ),
                                onChanged: (v) => price = v,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Price is required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: period,
                                decoration: const InputDecoration(
                                  labelText: 'Billing Recurrence',
                                  hintText: 'e.g. / month',
                                ),
                                onChanged: (v) => period = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: maxDevices.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Max Device Leases',
                                  hintText: 'e.g. 5',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final parsed = int.tryParse(v);
                                  if (parsed != null) maxDevices = parsed;
                                },
                                validator: (v) {
                                  if (v == null || int.tryParse(v) == null) return 'Enter valid count';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: maxBranches.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Max Shop Locations',
                                  hintText: 'e.g. 3',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final parsed = int.tryParse(v);
                                  if (parsed != null) maxBranches = parsed;
                                },
                                validator: (v) {
                                  if (v == null || int.tryParse(v) == null) return 'Enter valid count';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: featuresController,
                          decoration: const InputDecoration(
                            labelText: 'Core Features (Comma-Separated)',
                            hintText: 'e.g. Unlimited Bills, Real-time Sync, Priority Support',
                            helperText: 'Separate each platform feature with a comma.',
                          ),
                          maxLines: 3,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'At least one feature is required' : null,
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Mark as Recommended ("Popular" Tag)',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          value: isPopular,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                          onChanged: (v) => setDialogState(() => isPopular = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      ref.read(plansListProvider.notifier).archivePlan(existingPlan.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tier successfully archived from system.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Archive Plan'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      // Process comma separated features list
                      final list = featuresController.text
                          .split(',')
                          .map((f) => f.trim())
                          .where((f) => f.isNotEmpty)
                          .toList();

                      final plan = PlanModel(
                        id: isEditing ? existingPlan.id : 'tier_${DateTime.now().millisecondsSinceEpoch}',
                        title: title.trim(),
                        description: description.trim(),
                        price: price.trim(),
                        period: period.trim(),
                        maxDevices: maxDevices,
                        maxBranches: maxBranches,
                        features: list,
                        isPopular: isPopular,
                      );

                      if (isEditing) {
                        ref.read(plansListProvider.notifier).updatePlan(plan);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Subscription package reconfigured successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        ref.read(plansListProvider.notifier).addPlan(plan);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New subscription tier deployed!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Save Configurations' : 'Publish Plan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansListProvider).where((p) => !p.isArchived).toList();

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
                  onPressed: () => _showAddOrEditPlanDialog(),
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

            // 2. Dynamic Premium Plan Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                
                if (plans.isEmpty) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      'No active subscription plans found. Click "Create Tier" to deploy.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plans.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 1,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: isWide ? 0.72 : 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _PricingCard(
                      plan: plan,
                      onEditPressed: () => _showAddOrEditPlanDialog(existingPlan: plan),
                    );
                  },
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
  final PlanModel plan;
  final VoidCallback onEditPressed;

  const _PricingCard({
    required this.plan,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: plan.isPopular 
            ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.02))
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isPopular 
              ? AppColors.primary 
              : (isDark ? const Color(0xFF374151) : Colors.grey.shade200),
          width: plan.isPopular ? 2.5 : 1.5,
        ),
        boxShadow: plan.isPopular ? [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular Badge Overlay
          if (plan.isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.only(bottom: 16),
              child: const Text(
                'MOST RECOMMENDED',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
              ),
            ),
          
          Text(plan.title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(plan.price, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(plan.period, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
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
              itemCount: plan.features.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                return Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan.features[idx],
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
              onPressed: onEditPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: plan.isPopular ? AppColors.primary : Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: plan.isPopular ? AppColors.primary : null,
                backgroundColor: plan.isPopular ? plan.isPopular ? AppColors.primary.withValues(alpha: 0.05) : null : null,
              ),
              child: const Text('Edit Plan Structure', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
