class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? whatsappNumber;
  final int loyaltyPoints;
  final double totalSpent;
  final double pendingDues;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.whatsappNumber,
    this.loyaltyPoints = 0,
    this.totalSpent = 0.0,
    this.pendingDues = 0.0,
  });

  bool get isVip => totalSpent >= 10000 || loyaltyPoints >= 300;

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? whatsappNumber,
    int? loyaltyPoints,
    double? totalSpent,
    double? pendingDues,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      pendingDues: pendingDues ?? this.pendingDues,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'loyaltyPoints': loyaltyPoints,
      'totalSpent': totalSpent,
      'pendingDues': pendingDues,
    };
  }
}
