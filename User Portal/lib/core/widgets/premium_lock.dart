import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import 'premium_paywall_dialog.dart';

class PremiumLock extends ConsumerWidget {
  final Widget child;
  final String premiumExplanation;

  const PremiumLock({
    super.key,
    required this.child,
    required this.premiumExplanation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    if (subState.isPremium) {
      return child;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // The original child blurred/disabled
        Opacity(
          opacity: 0.4,
          child: AbsorbPointer(
            absorbing: true,
            child: child,
          ),
        ),
        // The luxury locked card overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.01),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showPremiumPaywallDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          premiumExplanation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
