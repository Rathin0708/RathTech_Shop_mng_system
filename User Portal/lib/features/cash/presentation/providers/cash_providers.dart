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
    this.openingFloat = 0.0,  // Set by Owner when opening shift
    this.cashSales = 0.0,
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
  CashDrawerNotifier() : super(CashDrawerState(journal: []));

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
}

final cashDrawerProvider = StateNotifierProvider<CashDrawerNotifier, CashDrawerState>((ref) {
  return CashDrawerNotifier();
});
