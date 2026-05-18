import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device_model.dart';

class DevicesListNotifier extends StateNotifier<List<DeviceModel>> {
  DevicesListNotifier() : super(_defaultDevices);

  static final List<DeviceModel> _defaultDevices = [
    const DeviceModel(
      id: 'TERM-AX901',
      tenant: 'Sri Kumaran Groceries',
      os: 'Windows 11',
      ip: '192.168.1.45',
      version: 'v1.4.2',
      status: 'Online',
      lastSeen: 'Active Now',
    ),
    const DeviceModel(
      id: 'TERM-BR402',
      tenant: 'Sri Kumaran Groceries',
      os: 'Android 13 (Sunmi POS)',
      ip: '192.168.1.48',
      version: 'v1.4.2',
      status: 'Offline',
      lastSeen: '2 hours ago',
    ),
    const DeviceModel(
      id: 'TERM-CL112',
      tenant: 'Sangeetha Sweets',
      os: 'Windows 10',
      ip: '112.85.4.22',
      version: 'v1.4.0',
      status: 'Online',
      lastSeen: 'Active Now',
    ),
    const DeviceModel(
      id: 'TERM-DN774',
      tenant: 'Rathna Stores Mega',
      os: 'iPadOS 17',
      ip: '192.168.0.101',
      version: 'v1.4.2',
      status: 'Online',
      lastSeen: 'Active Now',
    ),
    const DeviceModel(
      id: 'TERM-EP009',
      tenant: 'Modern Bakers Co.',
      os: 'Android 12',
      ip: '10.0.2.15',
      version: 'v1.3.9',
      status: 'Offline',
      lastSeen: '5 days ago',
    ),
  ];

  void addDevice(DeviceModel device) {
    state = [...state, device];
  }

  void revokeDevice(String deviceId) {
    state = state.where((d) => d.id != deviceId).toList();
  }

  void toggleStatus(String deviceId) {
    state = [
      for (final d in state)
        if (d.id == deviceId)
          d.copyWith(
            status: d.status == 'Online' ? 'Offline' : 'Online',
            lastSeen: d.status == 'Online' ? 'Just now offline' : 'Active Now',
          )
        else
          d
    ];
  }
}

final devicesListProvider = StateNotifierProvider<DevicesListNotifier, List<DeviceModel>>((ref) {
  return DevicesListNotifier();
});
