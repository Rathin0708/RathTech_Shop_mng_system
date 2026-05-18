class PlanModel {
  final String id;
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool isPopular;
  final int maxDevices;
  final int maxBranches;
  final bool isArchived;

  const PlanModel({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    this.isPopular = false,
    required this.maxDevices,
    required this.maxBranches,
    this.isArchived = false,
  });

  PlanModel copyWith({
    String? id,
    String? title,
    String? price,
    String? period,
    String? description,
    List<String>? features,
    bool? isPopular,
    int? maxDevices,
    int? maxBranches,
    bool? isArchived,
  }) {
    return PlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      period: period ?? this.period,
      description: description ?? this.description,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
      maxDevices: maxDevices ?? this.maxDevices,
      maxBranches: maxBranches ?? this.maxBranches,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
