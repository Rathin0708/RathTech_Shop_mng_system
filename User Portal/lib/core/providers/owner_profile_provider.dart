import 'package:flutter_riverpod/flutter_riverpod.dart';

class OwnerProfileState {
  final String ownerName;
  final String whatsappNumber;
  final bool autoSendWhatsapp;

  // Staff granular feature toggles
  final bool staffShowDashboard;
  final bool staffShowBilling;
  final bool staffShowInventory;
  final bool staffShowSales;
  final bool staffShowCrm;
  final bool staffShowCashDrawer;

  const OwnerProfileState({
    this.ownerName = 'RathTech Owner',
    this.whatsappNumber = '919876543210',
    this.autoSendWhatsapp = true,
    this.staffShowDashboard = true,
    this.staffShowBilling = true,
    this.staffShowInventory = true,
    this.staffShowSales = false,
    this.staffShowCrm = true,
    this.staffShowCashDrawer = true,
  });

  OwnerProfileState copyWith({
    String? ownerName,
    String? whatsappNumber,
    bool? autoSendWhatsapp,
    bool? staffShowDashboard,
    bool? staffShowBilling,
    bool? staffShowInventory,
    bool? staffShowSales,
    bool? staffShowCrm,
    bool? staffShowCashDrawer,
  }) {
    return OwnerProfileState(
      ownerName: ownerName ?? this.ownerName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      autoSendWhatsapp: autoSendWhatsapp ?? this.autoSendWhatsapp,
      staffShowDashboard: staffShowDashboard ?? this.staffShowDashboard,
      staffShowBilling: staffShowBilling ?? this.staffShowBilling,
      staffShowInventory: staffShowInventory ?? this.staffShowInventory,
      staffShowSales: staffShowSales ?? this.staffShowSales,
      staffShowCrm: staffShowCrm ?? this.staffShowCrm,
      staffShowCashDrawer: staffShowCashDrawer ?? this.staffShowCashDrawer,
    );
  }
}

class OwnerProfileNotifier extends StateNotifier<OwnerProfileState> {
  OwnerProfileNotifier() : super(const OwnerProfileState());

  void updateProfile({
    String? ownerName,
    String? whatsappNumber,
    bool? autoSendWhatsapp,
    bool? staffShowDashboard,
    bool? staffShowBilling,
    bool? staffShowInventory,
    bool? staffShowSales,
    bool? staffShowCrm,
    bool? staffShowCashDrawer,
  }) {
    state = state.copyWith(
      ownerName: ownerName,
      whatsappNumber: whatsappNumber,
      autoSendWhatsapp: autoSendWhatsapp,
      staffShowDashboard: staffShowDashboard,
      staffShowBilling: staffShowBilling,
      staffShowInventory: staffShowInventory,
      staffShowSales: staffShowSales,
      staffShowCrm: staffShowCrm,
      staffShowCashDrawer: staffShowCashDrawer,
    );
  }
}

final ownerProfileProvider = StateNotifierProvider<OwnerProfileNotifier, OwnerProfileState>((ref) {
  return OwnerProfileNotifier();
});
