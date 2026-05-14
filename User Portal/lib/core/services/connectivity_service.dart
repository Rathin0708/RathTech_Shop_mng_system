import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';

class ConnectivityService extends StateNotifier<bool> {
  final SyncService _syncService;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final Connectivity _connectivity = Connectivity();

  ConnectivityService(this._syncService) : super(false) {
    _init();
  }

  Future<void> _init() async {
    // 1. Initial status check on boot
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint("⚠️ Connectivity check failed during bootstrap: $e");
    }

    // 2. Subscribe to continuous connection change broadcasts
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Check if any active network interfaces exist
    final bool hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    // Trigger auto-sync only when transitioning from OFFLINE (false) to ONLINE (true)
    if (hasConnection && !state) {
      debugPrint("🌐 ConnectivityService: Connection Restored. Sweeping unsynced bills...");
      _syncService.syncOfflineBills('tenant_shop_01');
    }

    // Update StateNotifier payload to broadcast to all Riverpod UI consumers
    state = hasConnection;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

