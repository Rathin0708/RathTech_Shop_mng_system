import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/tenant_model.dart';

final tenantsListProvider = StateNotifierProvider<TenantsNotifier, List<TenantModel>>((ref) {
  return TenantsNotifier();
});

class TenantsNotifier extends StateNotifier<List<TenantModel>> {
  TenantsNotifier() : super(_dummyTenants);

  void addTenant(TenantModel tenant) {
    state = [tenant, ...state];
  }

  void updateStatus(String tenantId, TenantStatus status) {
    state = [
      for (final t in state)
        if (t.id == tenantId)
          TenantModel(
            id: t.id,
            businessName: t.businessName,
            ownerName: t.ownerName,
            contactEmail: t.contactEmail,
            contactPhone: t.contactPhone,
            gstNumber: t.gstNumber,
            logoUrl: t.logoUrl,
            category: t.category,
            status: status,
            currentPlanId: t.currentPlanId,
            subscriptionExpiresAt: t.subscriptionExpiresAt,
            activeModules: t.activeModules,
            maxDevices: t.maxDevices,
            maxBranches: t.maxBranches,
            maxEmployees: t.maxEmployees,
            createdAt: t.createdAt,
          )
        else
          t
    ];
  }

  static final List<TenantModel> _dummyTenants = [
    TenantModel(
      id: 'ten_01',
      businessName: 'A2B Sweets & Snacks',
      ownerName: 'Venkatesh Raj',
      contactEmail: 'admin@a2b.in',
      contactPhone: '+91 98765 43210',
      gstNumber: '33AABCA1234A1Z2',
      category: ShopCategory.restaurant,
      status: TenantStatus.active,
      currentPlanId: 'enterprise_monthly',
      subscriptionExpiresAt: DateTime.now().add(const Duration(days: 180)),
      activeModules: {'billing': true, 'inventory': true, 'accounting': true},
      maxDevices: 10,
      maxBranches: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    TenantModel(
      id: 'ten_02',
      businessName: 'Apollo Pharmacy Lane 4',
      ownerName: 'Dr. Ramesh Kumar',
      contactEmail: 'hassan@apollopharm.com',
      contactPhone: '+91 88990 11223',
      gstNumber: '29ACDPR8842M1Z9',
      category: ShopCategory.pharmacy,
      status: TenantStatus.active,
      currentPlanId: 'pro_annual',
      subscriptionExpiresAt: DateTime.now().add(const Duration(days: 34)),
      activeModules: {'billing': true, 'inventory': true},
      maxDevices: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    TenantModel(
      id: 'ten_03',
      businessName: 'Saravana Garments',
      ownerName: 'Manoj Kumar S',
      contactEmail: 'retail@saravanastore.in',
      contactPhone: '+91 77665 44332',
      category: ShopCategory.garments,
      status: TenantStatus.trial,
      currentPlanId: 'trial_14d',
      subscriptionExpiresAt: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
    TenantModel(
      id: 'ten_04',
      businessName: 'Nilgiris Supermarket',
      ownerName: 'Sunil Abraham',
      contactEmail: 'abraham.s@nilgiris.co',
      contactPhone: '+91 99001 88223',
      gstNumber: '33AXCPR9090R1ZD',
      category: ShopCategory.kirana,
      status: TenantStatus.suspended,
      currentPlanId: 'basic_monthly',
      subscriptionExpiresAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];
}
