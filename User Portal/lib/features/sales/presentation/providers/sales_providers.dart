import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_db/isar_provider.dart';
import '../../../../core/local_db/models/bill_model.dart';

/// Refreshes dynamically from Isar disk cache yielding all historical transaction objects.
final salesHistoryProvider = FutureProvider.autoDispose<List<BillModel>>((ref) async {
  final isar = ref.watch(isarServiceProvider);
  return await isar.getAllBills();
});
