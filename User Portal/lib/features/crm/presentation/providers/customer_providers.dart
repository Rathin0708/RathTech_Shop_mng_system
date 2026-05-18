import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/customer_model.dart';

final customersListProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) {
  return CustomersNotifier();
});

class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  CustomersNotifier() : super([]);

  void registerCustomer(String name, String phone, String email) {
    final newCust = CustomerModel(
      id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: email.isEmpty ? null : email,
      loyaltyPoints: 10, // Welcome loyalty points
      totalSpent: 0.0,
      pendingDues: 0.0,
    );
    
    state = [...state, newCust];
  }

  void addLoyaltyPoints(String customerId, int points) {
    state = [
      for (final cust in state)
        if (cust.id == customerId)
          cust.copyWith(loyaltyPoints: cust.loyaltyPoints + points)
        else
          cust
    ];
  }

  void recordPurchase(String customerId, double amount) {
    state = [
      for (final cust in state)
        if (cust.id == customerId)
          cust.copyWith(
            totalSpent: cust.totalSpent + amount,
            loyaltyPoints: cust.loyaltyPoints + (amount ~/ 100), // 1 point per ₹100
          )
        else
          cust
    ];
  }

  void settleDues(String customerId, double amount) {
    state = [
      for (final cust in state)
        if (cust.id == customerId)
          cust.copyWith(
            pendingDues: (cust.pendingDues - amount < 0) ? 0.0 : cust.pendingDues - amount
          )
        else
          cust
    ];
  }


}

