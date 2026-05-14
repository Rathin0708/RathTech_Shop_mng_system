import 'package:cloud_firestore/cloud_firestore.dart';

enum TenantStatus {
  active,
  suspended,
  trial,
  expired,
  blocked
}

enum ShopCategory {
  kirana,
  pharmacy,
  garments,
  electronics,
  jewellery,
  bakery,
  salon,
  wholesale,
  restaurant,
  general
}

class TenantModel {
  final String id;
  final String businessName;
  final String? ownerName;
  final String contactEmail;
  final String contactPhone;
  final String? gstNumber;
  final String? logoUrl;
  final ShopCategory category;
  
  // Subscription Controls
  final TenantStatus status;
  final String currentPlanId;
  final DateTime subscriptionExpiresAt;
  
  // Dynamic System Enablers (Feature Flags)
  final Map<String, bool> activeModules;
  
  // Restrictions
  final int maxDevices;
  final int maxBranches;
  final int maxEmployees;
  
  final DateTime createdAt;

  TenantModel({
    required this.id,
    required this.businessName,
    this.ownerName,
    required this.contactEmail,
    required this.contactPhone,
    this.gstNumber,
    this.logoUrl,
    required this.category,
    this.status = TenantStatus.trial,
    required this.currentPlanId,
    required this.subscriptionExpiresAt,
    this.activeModules = const {},
    this.maxDevices = 2,
    this.maxBranches = 1,
    this.maxEmployees = 3,
    required this.createdAt,
  });

  factory TenantModel.fromMap(Map<String, dynamic> map, String docId) {
    return TenantModel(
      id: docId,
      businessName: map['businessName'] ?? '',
      ownerName: map['ownerName'],
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      gstNumber: map['gstNumber'],
      logoUrl: map['logoUrl'],
      category: _parseCategory(map['category']),
      status: _parseStatus(map['status']),
      currentPlanId: map['currentPlanId'] ?? 'free_trial',
      subscriptionExpiresAt: (map['subscriptionExpiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activeModules: Map<String, bool>.from(map['activeModules'] ?? {}),
      maxDevices: map['maxDevices'] ?? 2,
      maxBranches: map['maxBranches'] ?? 1,
      maxEmployees: map['maxEmployees'] ?? 3,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'gstNumber': gstNumber,
      'logoUrl': logoUrl,
      'category': category.name,
      'status': status.name,
      'currentPlanId': currentPlanId,
      'subscriptionExpiresAt': Timestamp.fromDate(subscriptionExpiresAt),
      'activeModules': activeModules,
      'maxDevices': maxDevices,
      'maxBranches': maxBranches,
      'maxEmployees': maxEmployees,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Utility parsers
  static ShopCategory _parseCategory(String? val) {
    if (val == null) return ShopCategory.general;
    return ShopCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ShopCategory.general,
    );
  }

  static TenantStatus _parseStatus(String? val) {
    if (val == null) return TenantStatus.trial;
    return TenantStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TenantStatus.trial,
    );
  }
  
  bool get hasBillingModule => activeModules['billing'] ?? false;
  bool get hasInventoryModule => activeModules['inventory'] ?? false;
}
