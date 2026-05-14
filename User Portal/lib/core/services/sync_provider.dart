import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/isar_provider.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return SyncService(isarService);
});
