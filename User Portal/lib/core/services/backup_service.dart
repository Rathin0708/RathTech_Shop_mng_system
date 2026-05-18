import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/isar_provider.dart';
import '../../../features/cash/presentation/providers/cash_providers.dart';
import '../../../features/crm/presentation/providers/customer_providers.dart';
import '../../../features/inventory/presentation/providers/product_providers.dart';

class BackupResult {
  final bool success;
  final String message;
  const BackupResult({required this.success, required this.message});
}

class BackupService {
  final Ref _ref;

  BackupService(this._ref);

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<BackupResult> runCloudBackup({
    required String tenantId,
    required String performedBy,
    required bool products,
    required bool customers,
    required bool bills,
    required bool cashFlow,
    required bool staff,
  }) async {
    final db = _firestore;
    if (db == null) {
      return const BackupResult(success: false, message: "Firebase is offline or not configured.");
    }

    try {
      final backupId = 'BKP-${DateTime.now().millisecondsSinceEpoch}';
      final payload = <String, dynamic>{
        'backupId': backupId,
        'timestamp': FieldValue.serverTimestamp(),
        'performedBy': performedBy,
        'tenantId': tenantId,
        'modules': [],
      };

      // 1. Products Catalog Backup
      if (products) {
        payload['modules'].add('products');
        final productList = _ref.read(productsListProvider);
        payload['products'] = productList.map((p) => p.toMap()).toList();
        payload['productsCount'] = productList.length;
      }

      // 2. Customers / CRM Backup
      if (customers) {
        payload['modules'].add('customers');
        final customerList = _ref.read(customersListProvider);
        payload['customers'] = customerList.map((c) => c.toMap()).toList();
        payload['customersCount'] = customerList.length;
      }

      // 3. Bills / Sales History Backup
      if (bills) {
        payload['modules'].add('bills');
        final isarService = _ref.read(isarServiceProvider);
        final billList = await isarService.getAllBills();
        payload['bills'] = billList.map((bill) => {
          'invoiceNumber': bill.invoiceNumber,
          'timestamp': bill.timestamp.toIso8601String(),
          'subtotal': bill.subtotal,
          'gstAmount': bill.gstAmount,
          'netTotal': bill.netTotal,
          'paymentMethod': bill.paymentMethod,
          'isSyncedToCloud': bill.isSyncedToCloud,
          'items': bill.purchasedItems.map((i) => {
            'productId': i.productId,
            'productName': i.productName,
            'quantity': i.quantity,
            'unitPrice': i.unitPrice,
            'lineTotal': i.lineTotal,
          }).toList(),
        }).toList();
        payload['billsCount'] = billList.length;
      }

      // 4. Cash Flow Journal Backup
      if (cashFlow) {
        payload['modules'].add('cashFlow');
        final cashState = _ref.read(cashDrawerProvider);
        payload['cashFlow'] = {
          'openingFloat': cashState.openingFloat,
          'cashSales': cashState.cashSales,
          'journal': cashState.journal.map((tx) => {
            'id': tx.id,
            'reason': tx.reason,
            'amount': tx.amount,
            'type': tx.type,
            'timestamp': tx.timestamp.toIso8601String(),
          }).toList(),
        };
        payload['cashTransactionsCount'] = cashState.journal.length;
      }

      // 5. Staff Accounts Backup
      if (staff) {
        payload['modules'].add('staff');
        // Fetch all staff credentials stored under Firestore linked to this tenant
        final staffSnapshot = await db
            .collection('users')
            .where('tenantId', isEqualTo: tenantId)
            .get();
        
        final staffList = staffSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': data['uid'],
            'email': data['email'],
            'name': data['name'],
            'role': data['role'],
            'isActive': data['isActive'],
            'createdAt': data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
                : null,
          };
        }).toList();
        
        payload['staff'] = staffList;
        payload['staffCount'] = staffList.length;
      }

      // 6. Write Snapshot to Firestore under tenant backups
      await db
          .collection('tenants')
          .doc(tenantId)
          .collection('backups')
          .doc(backupId)
          .set(payload, SetOptions(merge: true));

      return BackupResult(
        success: true,
        message: "🎉 Cloud Backup snapshot $backupId completed successfully!",
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: "Backup failed: $e",
      );
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
