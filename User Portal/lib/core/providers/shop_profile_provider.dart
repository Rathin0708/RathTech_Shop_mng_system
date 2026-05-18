import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_model.dart';

class ShopProfileNotifier extends StateNotifier<ShopCategory> {
  ShopProfileNotifier() : super(ShopCategory.general);

  void updateCategory(ShopCategory category) {
    state = category;
  }
}

final shopProfileProvider = StateNotifierProvider<ShopProfileNotifier, ShopCategory>((ref) {
  return ShopProfileNotifier();
});
