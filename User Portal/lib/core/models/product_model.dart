import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class ProductModel {
  Id localId = Isar.autoIncrement; // Direct Isar Local primary auto-key
  
  @Index(unique: true, replace: true)
  late String id; // Cloud DB reference string
  
  late String name;
  
  @Index()
  late String category;
  
  @Index(unique: true)
  late String sku;
  
  late String? barcode;
  
  late double costPrice;
  late double sellingPrice;
  late int currentStock;
  late int lowStockAlertLevel;
  late String? imageUrl;

  // Essential empty constructor for Isar
  ProductModel();

  // Extended helper to create instance comfortably
  static ProductModel create({
    required String id,
    required String name,
    required String category,
    required String sku,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    required int currentStock,
    int lowStockAlertLevel = 10,
    String? imageUrl,
  }) {
    final p = ProductModel();
    p.id = id;
    p.name = name;
    p.category = category;
    p.sku = sku;
    p.barcode = barcode;
    p.costPrice = costPrice;
    p.sellingPrice = sellingPrice;
    p.currentStock = currentStock;
    p.lowStockAlertLevel = lowStockAlertLevel;
    p.imageUrl = imageUrl;
    return p;
  }

  @ignore // Prevent Isar from trying to persist getter values directly
  bool get isLowStock => currentStock <= lowStockAlertLevel;
  
  @ignore
  bool get isOutOfStock => currentStock <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sku': sku,
      'barcode': barcode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'lowStockAlertLevel': lowStockAlertLevel,
      'imageUrl': imageUrl,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    final p = ProductModel();
    p.id = docId;
    p.name = map['name'] ?? '';
    p.category = map['category'] ?? 'General';
    p.sku = map['sku'] ?? '';
    p.barcode = map['barcode'];
    p.costPrice = (map['costPrice'] as num?)?.toDouble() ?? 0.0;
    p.sellingPrice = (map['sellingPrice'] as num?)?.toDouble() ?? 0.0;
    p.currentStock = (map['currentStock'] as num?)?.toInt() ?? 0;
    p.lowStockAlertLevel = (map['lowStockAlertLevel'] as num?)?.toInt() ?? 10;
    p.imageUrl = map['imageUrl'];
    return p;
  }
}
