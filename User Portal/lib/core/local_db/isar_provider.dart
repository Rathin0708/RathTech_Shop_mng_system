import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});
