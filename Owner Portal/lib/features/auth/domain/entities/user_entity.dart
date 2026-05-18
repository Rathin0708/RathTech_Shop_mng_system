enum UserRole {
  superOwner,       // Overarching SaaS system owner (Super Admin)
  admin,            // General Administrator
  supportStaff,     // Staff handling customer service & ticket logs
  financeManager,   // View financials & MRR records
  salesManager,     // Handle tenant growth & onboarding campaigns
  technicalTeam,    // Manage devices, remote configs & parameters
  readOnlyAnalyst   // Diagnostic read-only access
}

enum AdminPermission {
  manageTenants,    // Onboard, suspend, block tenant shops
  managePlans,      // Configure pricing packages & feature matrices
  manageDevices,    // Register, reset or revoke active terminal allocations
  viewFinancials,   // Access MRR metrics, lifetime collections & ARR SPLINE charts
  exportData,       // Export tenant lists, diagnostics log files
  customerSupport,  // Read and write ticket summaries, check sync queues
  configureSystem,  // Manage white-label themes, splash options & configs
}

extension UserRolePermissions on UserRole {
  Set<AdminPermission> get permissions {
    switch (this) {
      case UserRole.superOwner:
        return AdminPermission.values.toSet(); // Super Owner holds unrestricted authorization
      case UserRole.admin:
        return {
          AdminPermission.manageTenants,
          AdminPermission.manageDevices,
          AdminPermission.viewFinancials,
          AdminPermission.exportData,
          AdminPermission.customerSupport,
        };
      case UserRole.financeManager:
        return {
          AdminPermission.viewFinancials,
          AdminPermission.exportData,
        };
      case UserRole.salesManager:
        return {
          AdminPermission.manageTenants,
          AdminPermission.viewFinancials,
        };
      case UserRole.supportStaff:
        return {
          AdminPermission.customerSupport,
          AdminPermission.manageDevices,
        };
      case UserRole.technicalTeam:
        return {
          AdminPermission.manageDevices,
          AdminPermission.configureSystem,
        };
      case UserRole.readOnlyAnalyst:
        return {
          AdminPermission.viewFinancials,
        };
    }
  }
}

class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? tenantId; // Associated tenant shop profile if applicable
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

  // Permission Helpers
  bool get isSaaSOwner => role == UserRole.superOwner;
  bool get isShopOwner => role == UserRole.admin;
  
  bool hasPermission(AdminPermission permission) => role.permissions.contains(permission);
}
