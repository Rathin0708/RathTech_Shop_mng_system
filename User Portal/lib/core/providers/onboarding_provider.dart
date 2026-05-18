import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final bool settingsCustomized;
  final bool tamilSearchTried;
  final bool stockAdjusted;
  final bool pdfExported;
  final bool isDismissed;

  const OnboardingState({
    this.settingsCustomized = false,
    this.tamilSearchTried = false,
    this.stockAdjusted = false,
    this.pdfExported = false,
    this.isDismissed = false,
  });

  int get completedStepsCount {
    int count = 0;
    if (settingsCustomized) count++;
    if (tamilSearchTried) count++;
    if (stockAdjusted) count++;
    if (pdfExported) count++;
    return count;
  }

  double get progressPercentage => completedStepsCount / 4.0;

  OnboardingState copyWith({
    bool? settingsCustomized,
    bool? tamilSearchTried,
    bool? stockAdjusted,
    bool? pdfExported,
    bool? isDismissed,
  }) {
    return OnboardingState(
      settingsCustomized: settingsCustomized ?? this.settingsCustomized,
      tamilSearchTried: tamilSearchTried ?? this.tamilSearchTried,
      stockAdjusted: stockAdjusted ?? this.stockAdjusted,
      pdfExported: pdfExported ?? this.pdfExported,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void completeStep(String step) {
    switch (step) {
      case 'settingsCustomized':
        state = state.copyWith(settingsCustomized: true);
        break;
      case 'tamilSearchTried':
        state = state.copyWith(tamilSearchTried: true);
        break;
      case 'stockAdjusted':
        state = state.copyWith(stockAdjusted: true);
        break;
      case 'pdfExported':
        state = state.copyWith(pdfExported: true);
        break;
    }
  }

  void reset() {
    state = const OnboardingState();
  }

  void dismiss() {
    state = state.copyWith(isDismissed: true);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
