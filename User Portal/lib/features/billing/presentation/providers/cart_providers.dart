import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/models/product_model.dart';
import '../../data/models/cart_item_model.dart';

class CartState {
  final List<CartItem> items;
  final double gstRate; // e.g. 18%
  final double flatDiscount;
  final CustomerModel? selectedCustomer;

  CartState({
    this.items = const [],
    this.gstRate = 18.0,
    this.flatDiscount = 0.0,
    this.selectedCustomer,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.itemSubtotal);
  
  double get discountAmount => items.fold(0.0, (sum, item) => sum + item.discountAmount) + flatDiscount;
  
  // GST is calculated after item discounts are subtracted
  double get taxableAmount => subtotal - discountAmount;
  
  double get gstAmount => taxableAmount * (gstRate / 100);

  double get netTotal => taxableAmount + gstAmount;

  CartState copyWith({
    List<CartItem>? items,
    double? gstRate,
    double? flatDiscount,
    CustomerModel? selectedCustomer,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      gstRate: gstRate ?? this.gstRate,
      flatDiscount: flatDiscount ?? this.flatDiscount,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void selectCustomer(CustomerModel customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void removeCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void addToCart(ProductModel product) {
    final existingIdx = state.items.indexWhere((item) => item.product.id == product.id);

    if (existingIdx != -1) {
      // Increment quantity if it exists already
      final existing = state.items[existingIdx];
      _updateQuantity(product.id, existing.quantity + 1);
    } else {
      // Add fresh cart item row
      state = state.copyWith(
        items: [...state.items, CartItem(product: product)],
      );
    }
  }

  void _updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId)
            item.copyWith(quantity: newQuantity)
          else
            item
      ],
    );
  }

  void incrementQuantity(String productId) {
    final item = state.items.firstWhere((element) => element.product.id == productId);
    _updateQuantity(productId, item.quantity + 1);
  }

  void decrementQuantity(String productId) {
    final item = state.items.firstWhere((element) => element.product.id == productId);
    _updateQuantity(productId, item.quantity - 1);
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void clearCart() {
    state = CartState(gstRate: state.gstRate);
  }

  void applyFlatDiscount(double amount) {
    state = state.copyWith(flatDiscount: amount);
  }

  void restoreCart(List<CartItem> restoredItems, CustomerModel? customer) {
    state = CartState(
      items: restoredItems,
      selectedCustomer: customer,
      gstRate: state.gstRate,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
