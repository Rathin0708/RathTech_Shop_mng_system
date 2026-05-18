import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/customer_model.dart';

final customersListProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) {
  return CustomersNotifier();
});

class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  CustomersNotifier() : super(_mockCustomers);

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

  static final List<CustomerModel> _mockCustomers = [
    const CustomerModel(
      id: 'CUST-001',
      name: 'Anand Kumar',
      phone: '9876543210',
      email: 'anand@gmail.com',
      loyaltyPoints: 450,
      totalSpent: 12450.0,
      pendingDues: 1500.0,
    ),
    const CustomerModel(
      id: 'CUST-002',
      name: 'Priya Sharma',
      phone: '8765432109',
      email: 'priya.s@outlook.com',
      loyaltyPoints: 120,
      totalSpent: 3200.0,
      pendingDues: 0.0,
    ),
    const CustomerModel(
      id: 'CUST-003',
      name: 'Karthik Raj',
      phone: '7654321098',
      loyaltyPoints: 890,
      totalSpent: 24890.0,
      pendingDues: 0.0,
    ),
    const CustomerModel(
      id: 'CUST-004',
      name: 'Meenakshi Nathan',
      phone: '9988776655',
      email: 'meena.n@yahoo.com',
      loyaltyPoints: 25,
      totalSpent: 950.0,
      pendingDues: 450.0,
    ),
  ];
}

