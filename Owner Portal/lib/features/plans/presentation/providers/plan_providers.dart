import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/plan_model.dart';

class PlansListNotifier extends StateNotifier<List<PlanModel>> {
  PlansListNotifier() : super(_defaultPlans);

  static final List<PlanModel> _defaultPlans = [
    const PlanModel(
      id: 'retail_starter',
      title: 'Retail Starter',
      price: '₹999',
      period: '/ month',
      description: 'Essential offline-first billing for independent corner shops.',
      maxDevices: 1,
      maxBranches: 1,
      features: [
        'Max 1 POS Register Device',
        'Unlimited Offline Billing',
        'Local Inventory Caching',
        'End-of-Day Mini Reports',
        'Standard Email Support',
      ],
      isPopular: false,
    ),
    const PlanModel(
      id: 'business_pro',
      title: 'Business Pro',
      price: '₹2,499',
      period: '/ month',
      description: 'Advanced inventory tracking and real-time multi-terminal sync.',
      maxDevices: 3,
      maxBranches: 3,
      features: [
        'Up to 3 Register Devices',
        'Real-time Cloud Sync Engine',
        'Low-Stock Predictive Alerts',
        'Comprehensive PDF Invoices',
        'Priority Chat Support',
        'Customer Loyalty Database',
      ],
      isPopular: true,
    ),
    const PlanModel(
      id: 'enterprise_fleet',
      title: 'Enterprise Fleet',
      price: '₹5,999',
      period: '/ month',
      description: 'Full multi-branch control center and custom API integrations.',
      maxDevices: 99,
      maxBranches: 99,
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
  ];

  void addPlan(PlanModel plan) {
    state = [...state, plan];
  }

  void updatePlan(PlanModel updatedPlan) {
    state = [
      for (final plan in state)
        if (plan.id == updatedPlan.id) updatedPlan else plan
    ];
  }

  void archivePlan(String planId) {
    state = [
      for (final plan in state)
        if (plan.id == planId) plan.copyWith(isArchived: true) else plan
    ];
  }
}

final plansListProvider = StateNotifierProvider<PlansListNotifier, List<PlanModel>>((ref) {
  return PlansListNotifier();
});
