import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_db/isar_provider.dart';
import '../../../../core/local_db/isar_service.dart';
import '../../../../core/models/product_model.dart';

final productsListProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return ProductsNotifier(isar);
});

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  final IsarService _isar;

  ProductsNotifier(this._isar) : super([]) {
    _initLocalDatabase();
  }

  Future<void> _initLocalDatabase() async {
    try {
      final cached = await _isar.getCachedProducts();
      if (cached.isEmpty) {
        // Seed default items into local Isar DB on first boot
        await _isar.cacheProducts(_mockCatalog);
        state = _mockCatalog;
      } else {
        state = cached;
      }
    } catch (e) {
      // Fallback to mock if something breaks during init
      state = _mockCatalog;
    }
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    final updatedProducts = [
      for (final p in state)
        if (p.id == productId)
          ProductModel.create(
            id: p.id,
            name: p.name,
            category: p.category,
            sku: p.sku,
            barcode: p.barcode,
            costPrice: p.costPrice,
            sellingPrice: p.sellingPrice,
            currentStock: p.currentStock + quantityChange,
            lowStockAlertLevel: p.lowStockAlertLevel,
            imageUrl: p.imageUrl,
          )
        else
          p
    ];

    state = updatedProducts;
    
    // Persist the full updated state to local Isar Cache in background
    try {
      await _isar.cacheProducts(updatedProducts);
    } catch (_) {
      // Fail silently or log in telemetry (Phase 49)
    }
  }

  static final List<ProductModel> _mockCatalog = [
    ProductModel.create(
      id: 'prod_01',
      name: 'Fortune Sunflower Oil 1L',
      category: 'Grocery',
      sku: 'FOR-SUN-1L',
      barcode: '8901234567890',
      costPrice: 145.00,
      sellingPrice: 170.00,
      currentStock: 48,
      lowStockAlertLevel: 15,
    ),
    ProductModel.create(
      id: 'prod_02',
      name: 'Aashirvaad Atta 5Kg',
      category: 'Atta & Flours',
      sku: 'AASH-ATT-5K',
      barcode: '8901234567891',
      costPrice: 280.00,
      sellingPrice: 310.00,
      currentStock: 8,
      lowStockAlertLevel: 10,
    ),
    ProductModel.create(
      id: 'prod_03',
      name: 'Tata Salt Premium 1Kg',
      category: 'Spices & Salt',
      sku: 'TATA-SALT-1K',
      barcode: '8901234567892',
      costPrice: 22.00,
      sellingPrice: 28.00,
      currentStock: 120,
    ),
    ProductModel.create(
      id: 'prod_04',
      name: 'Britannia Good Day Nuts 100g',
      category: 'Biscuits & Snacks',
      sku: 'BRIT-GD-100G',
      barcode: '8901234567893',
      costPrice: 25.00,
      sellingPrice: 35.00,
      currentStock: 0,
      lowStockAlertLevel: 20,
    ),
    ProductModel.create(
      id: 'prod_05',
      name: 'Surf Excel Easy Wash 1Kg',
      category: 'Detergents & Cleaning',
      sku: 'SURF-EX-1K',
      barcode: '8901234567894',
      costPrice: 135.00,
      sellingPrice: 160.00,
      currentStock: 35,
      lowStockAlertLevel: 5,
    ),
    ProductModel.create(
      id: 'prod_06',
      name: 'Maggi 2-Min Noodles 12-Pack',
      category: 'Instant Food',
      sku: 'MAGG-12PK',
      barcode: '8901234567895',
      costPrice: 144.00,
      sellingPrice: 168.00,
      currentStock: 14,
      lowStockAlertLevel: 10,
    ),
  ];
}

