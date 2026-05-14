class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int loyaltyPoints;
  final double totalSpent;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.loyaltyPoints = 0,
    this.totalSpent = 0.0,
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    int? loyaltyPoints,
    double? totalSpent,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}
