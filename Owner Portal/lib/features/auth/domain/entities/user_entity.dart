enum UserRole {
  superAdmin,     // Overarching SaaS system owner
  admin,          // Tenant owner/shop business owner
  manager,        // Branch/Store manager
  cashier,        // Sales register personnel
  accountant,     // Reports viewer only
  staff,          // Standard inventory/worker user
  analyst         // Read-only diagnostics user
}

class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? tenantId; // Required for all except global SuperAdmin
  final String? branchId;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.tenantId,
    this.branchId,
    this.isActive = true,
    required this.createdAt,
  });

  // Helper to check permissions
  bool get isSaaSOwner => role == UserRole.superAdmin;
  bool get isShopOwner => role == UserRole.admin;
}
