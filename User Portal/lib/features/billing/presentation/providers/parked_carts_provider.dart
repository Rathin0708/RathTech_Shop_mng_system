import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/customer_model.dart';
import '../../data/models/cart_item_model.dart';

class ParkedCart {
  final String id;
  final List<CartItem> items;
  final CustomerModel? customer;
  final DateTime parkedAt;
  final double totalValue;

  ParkedCart({
    required this.id,
    required this.items,
    this.customer,
    required this.parkedAt,
    required this.totalValue,
  });
}

class ParkedCartsNotifier extends StateNotifier<List<ParkedCart>> {
  ParkedCartsNotifier() : super(_mockParkedCarts);

  void parkCart(List<CartItem> items, CustomerModel? customer, double totalValue) {
    final newPark = ParkedCart(
      id: 'PARK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      items: items,
      customer: customer,
      parkedAt: DateTime.now(),
      totalValue: totalValue,
    );
    
    state = [newPark, ...state];
  }

  void removeParkedCart(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  static final List<ParkedCart> _mockParkedCarts = [];
}

final parkedCartsProvider = StateNotifierProvider<ParkedCartsNotifier, List<ParkedCart>>((ref) {
  return ParkedCartsNotifier();
});
