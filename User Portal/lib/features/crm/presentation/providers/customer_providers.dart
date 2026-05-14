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
    );
    
    state = [...state, newCust];
  }

  static final List<CustomerModel> _mockCustomers = [
    const CustomerModel(
      id: 'CUST-001',
      name: 'Anand Kumar',
      phone: '9876543210',
      email: 'anand@gmail.com',
      loyaltyPoints: 450,
      totalSpent: 12450.0,
    ),
    const CustomerModel(
      id: 'CUST-002',
      name: 'Priya Sharma',
      phone: '8765432109',
      email: 'priya.s@outlook.com',
      loyaltyPoints: 120,
      totalSpent: 3200.0,
    ),
    const CustomerModel(
      id: 'CUST-003',
      name: 'Karthik Raj',
      phone: '7654321098',
      loyaltyPoints: 890,
      totalSpent: 24890.0,
    ),
    const CustomerModel(
      id: 'CUST-004',
      name: 'Meenakshi Nathan',
      phone: '9988776655',
      email: 'meena.n@yahoo.com',
      loyaltyPoints: 25,
      totalSpent: 950.0,
    ),
  ];
}
