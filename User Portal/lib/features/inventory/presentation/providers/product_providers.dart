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
      state = cached; // start empty if no products added yet
    } catch (e) {
      state = []; // clean empty state on error
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

  Future<void> addProduct(ProductModel product) async {
    final updated = [...state, product];
    state = updated;
    try {
      await _isar.cacheProducts(updated);
    } catch (_) {
      // Fail silently
    }
  }

}

