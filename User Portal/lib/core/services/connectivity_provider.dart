import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'sync_provider.dart';

final connectivityServiceProvider = StateNotifierProvider<ConnectivityService, bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final service = ConnectivityService(syncService);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
