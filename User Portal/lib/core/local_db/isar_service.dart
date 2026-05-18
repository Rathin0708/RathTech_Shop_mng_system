import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';
import 'models/bill_model.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    String? path;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      path = dir.path;
    }
    
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [
          ProductModelSchema, // Generated via build_runner
          BillModelSchema,    // Generated via build_runner
        ],
        directory: path ?? '',
        inspector: !kIsWeb, // Enables Isar UI inspector in debug mode
      );
    }
    
    return Isar.getInstance()!;
  }

  // --- Product Caching Logic ---
  Future<void> cacheProducts(List<ProductModel> products) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.productModels.putAll(products);
    });
  }

  Future<List<ProductModel>> getCachedProducts() async {
    final isar = await db;
    return await isar.productModels.where().findAll();
  }

  // --- Transaction Logging ---
  Future<void> logTransaction(BillModel bill) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.billModels.put(bill);
    });
  }

  Future<List<BillModel>> getUnsyncedBills() async {
    final isar = await db;
    return await isar.billModels.filter().isSyncedToCloudEqualTo(false).findAll();
  }

  Future<List<BillModel>> getAllBills() async {
    final isar = await db;
    // Retrieves all local logs sorted reverse-chronologically (newest first)
    return await isar.billModels.where().sortByTimestampDesc().findAll();
  }
}
