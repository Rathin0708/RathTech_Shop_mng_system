import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionState {
  final bool isPremium;
  final int trialDaysRemaining;
  final bool isTrialActive;

  const SubscriptionState({
    this.isPremium = false,
    this.trialDaysRemaining = 11,
    this.isTrialActive = true,
  });

  SubscriptionState copyWith({
    bool? isPremium,
    int? trialDaysRemaining,
    bool? isTrialActive,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      isTrialActive: isTrialActive ?? this.isTrialActive,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  void upgradeToPremium() {
    state = state.copyWith(
      isPremium: true,
      isTrialActive: false,
      trialDaysRemaining: 0,
    );
  }

  void downgradeToFree() {
    state = const SubscriptionState(
      isPremium: false,
      isTrialActive: true,
      trialDaysRemaining: 14,
    );
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
