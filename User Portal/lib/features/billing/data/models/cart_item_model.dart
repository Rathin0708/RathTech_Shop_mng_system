import '../../../../core/models/product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;
  final double discountPercentage;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discountPercentage = 0.0,
  });

  double get unitPrice => product.sellingPrice;
  
  double get itemSubtotal => unitPrice * quantity;

  double get discountAmount => itemSubtotal * (discountPercentage / 100);

  double get finalTotal => itemSubtotal - discountAmount;

  CartItem copyWith({
    int? quantity,
    double? discountPercentage,
  }) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}
