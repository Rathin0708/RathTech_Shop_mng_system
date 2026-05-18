import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';
import 'models/bill_model.dart';

class IsarService {
  late Future<Isar>? db;

  // Web in-memory fallbacks to support zero-dependency browser usage
  final List<ProductModel> _webProducts = [];
  final List<BillModel> _webBills = [];

  IsarService() {
    if (!kIsWeb) {
      db = openDB();
    } else {
      db = null;
    }
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
        inspector: false,
      );
    }
    
    return Isar.getInstance()!;
  }

  // --- Product Caching Logic ---
  Future<void> cacheProducts(List<ProductModel> products) async {
    if (kIsWeb) {
      _webProducts.clear();
      _webProducts.addAll(products);
      return;
    }
    final isar = await db!;
    await isar.writeTxn(() async {
      await isar.productModels.putAll(products);
    });
  }

  Future<List<ProductModel>> getCachedProducts() async {
    if (kIsWeb) {
      return List.from(_webProducts);
    }
    final isar = await db!;
    return await isar.productModels.where().findAll();
  }

  // --- Transaction Logging ---
  Future<void> logTransaction(BillModel bill) async {
    if (kIsWeb) {
      // Find and replace, or insert new
      final idx = _webBills.indexWhere((b) => b.invoiceNumber == bill.invoiceNumber);
      if (idx != -1) {
        _webBills[idx] = bill;
      } else {
        _webBills.add(bill);
      }
      return;
    }
    final isar = await db!;
    await isar.writeTxn(() async {
      await isar.billModels.put(bill);
    });
  }

  Future<List<BillModel>> getUnsyncedBills() async {
    if (kIsWeb) {
      return _webBills.where((b) => !b.isSyncedToCloud).toList();
    }
    final isar = await db!;
    return await isar.billModels.filter().isSyncedToCloudEqualTo(false).findAll();
  }

  Future<List<BillModel>> getAllBills() async {
    if (kIsWeb) {
      final list = List<BillModel>.from(_webBills);
      // Sort reverse-chronologically by timestamp
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    final isar = await db!;
    // Retrieves all local logs sorted reverse-chronologically (newest first)
    return await isar.billModels.where().sortByTimestampDesc().findAll();
  }
}
