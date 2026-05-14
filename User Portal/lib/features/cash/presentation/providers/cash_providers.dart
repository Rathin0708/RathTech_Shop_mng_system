import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashTransaction {
  final String id;
  final String reason;
  final double amount;
  final String type; // 'Drop' (Cash removed to safe), 'Payout' (Vendor payment), 'Add' (Added float)
  final DateTime timestamp;

  CashTransaction({
    required this.id,
    required this.reason,
    required this.amount,
    required this.type,
    required this.timestamp,
  });
}

class CashDrawerState {
  final double openingFloat;
  final double cashSales;
  final List<CashTransaction> journal;

  CashDrawerState({
    this.openingFloat = 5000.0, // Default opening float ₹5000
    this.cashSales = 14520.0,    // Simulated cash sales
    this.journal = const [],
  });

  double get totalIn => journal.where((t) => t.type == 'Add').fold(0.0, (sum, t) => sum + t.amount);
  double get totalOut => journal.where((t) => t.type != 'Add').fold(0.0, (sum, t) => sum + t.amount);

  double get expectedCash => openingFloat + cashSales + totalIn - totalOut;

  CashDrawerState copyWith({
    double? openingFloat,
    double? cashSales,
    List<CashTransaction>? journal,
  }) {
    return CashDrawerState(
      openingFloat: openingFloat ?? this.openingFloat,
      cashSales: cashSales ?? this.cashSales,
      journal: journal ?? this.journal,
    );
  }
}

class CashDrawerNotifier extends StateNotifier<CashDrawerState> {
  CashDrawerNotifier() : super(CashDrawerState(journal: _initialJournal));

  void logCashAction(String reason, double amount, String type) {
    final tx = CashTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      reason: reason,
      amount: amount,
      type: type,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(journal: [tx, ...state.journal]);
  }

  void resetDrawer(double newFloat) {
    state = CashDrawerState(
      openingFloat: newFloat,
      cashSales: 0.0,
      journal: [],
    );
  }

  static final List<CashTransaction> _initialJournal = [
    CashTransaction(
      id: 'TX-99101',
      reason: 'Vendor Payout: Daily Milk Delivery',
      amount: 450.0,
      type: 'Payout',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CashTransaction(
      id: 'TX-99102',
      reason: 'Midday Cash Drop to Safe Deposit',
      amount: 5000.0,
      type: 'Drop',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
}

final cashDrawerProvider = StateNotifierProvider<CashDrawerNotifier, CashDrawerState>((ref) {
  return CashDrawerNotifier();
});
