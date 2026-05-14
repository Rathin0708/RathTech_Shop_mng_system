enum UserRole {
  superAdmin,
  admin,
  manager,
  cashier,
  accountant,
  staff,
  analyst
}

class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? tenantId;
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

  bool get isSaaSOwner => role == UserRole.superAdmin;
  bool get isShopOwner => role == UserRole.admin;
}
