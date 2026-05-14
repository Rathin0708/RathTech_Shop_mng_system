import 'package:isar/isar.dart';

part 'bill_model.g.dart';

@collection
class BillModel {
  Id localId = Isar.autoIncrement;

  @Index(unique: true)
  late String invoiceNumber;

  late DateTime timestamp;
  
  late double subtotal;
  late double gstAmount;
  late double netTotal;
  
  late String paymentMethod; // 'Cash', 'UPI', 'Card'
  late bool isSyncedToCloud; // Important flag for sync logic (Phase 41)

  late List<CartItemEmbedded> purchasedItems;

  BillModel();
}

@embedded
class CartItemEmbedded {
  late String productId;
  late String productName;
  late int quantity;
  late double unitPrice;
  late double lineTotal;

  CartItemEmbedded();
}
