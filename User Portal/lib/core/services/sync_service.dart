import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../local_db/isar_service.dart';
import '../local_db/models/bill_model.dart';

class SyncService {
  final IsarService _isarService;
  
  SyncService(this._isarService);

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Triggers direct sweep of local Isar database and attempts background push to Cloud Firestore
  Future<SyncResult> syncOfflineBills(String tenantId) async {
    try {
      // 1. Gather all unsynced local records
      final unsynced = await _isarService.getUnsyncedBills();
      if (unsynced.isEmpty) {
        return SyncResult(successCount: 0, failedCount: 0, message: "Database already synced.");
      }

      debugPrint("🔄 SyncEngine: Detected ${unsynced.length} local invoices awaiting Cloud backup...");

      int pushedCount = 0;
      int failedCount = 0;

      // 2. Batch process records into remote Firestore collections
      for (final bill in unsynced) {
        final success = await _pushBillToFirestore(tenantId, bill);
        if (success) {
          pushedCount++;
        } else {
          failedCount++;
        }
      }

      return SyncResult(
        successCount: pushedCount,
        failedCount: failedCount,
        message: "Cloud Sync completed. Uploaded $pushedCount invoices successfully.",
      );
    } catch (e) {
      return SyncResult(
        successCount: 0,
        failedCount: 0,
        message: "Sync Operation interrupted. Check connection: $e",
      );
    }
  }

  Future<bool> _pushBillToFirestore(String tenantId, BillModel bill) async {
    try {
      // Map the structured Isar Model to generic dynamic Firestore Map payload
      final payload = {
        'invoiceNumber': bill.invoiceNumber,
        'timestamp': FieldValue.serverTimestamp(), // Utilize Firestore server time
        'subtotal': bill.subtotal,
        'gstAmount': bill.gstAmount,
        'netTotal': bill.netTotal,
        'paymentMethod': bill.paymentMethod,
        'items': bill.purchasedItems.map((i) => {
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
          'lineTotal': i.lineTotal,
        }).toList(),
      };

      final db = _firestore;
      if (db == null) {
        debugPrint("⚠️ SyncEngine Bypassed: Firebase is not configured or running in Local-Only Mode.");
        return false;
      }

      // Write document to the Tenant specific collection path ensuring strict isolation
      await db
          .collection('tenants')
          .doc(tenantId)
          .collection('transactions')
          .doc(bill.invoiceNumber)
          .set(payload, SetOptions(merge: true));

      // Write successful! Update local Isar flag to true so it isn't scanned again
      bill.isSyncedToCloud = true;
      await _isarService.logTransaction(bill);

      debugPrint("✅ SyncEngine: Invoice ${bill.invoiceNumber} successfully backed up to Firestore.");
      return true;
    } catch (e) {
      debugPrint("⚠️ SyncEngine Failed: Unable to backup ${bill.invoiceNumber} to Cloud: $e");
      return false;
    }
  }
}

class SyncResult {
  final int successCount;
  final int failedCount;
  final String message;

  SyncResult({
    required this.successCount,
    required this.failedCount,
    required this.message,
  });
}
