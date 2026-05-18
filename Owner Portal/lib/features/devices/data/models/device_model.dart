class DeviceModel {
  final String id;
  final String tenant;
  final String os;
  final String ip;
  final String version;
  final String status; // 'Online' or 'Offline'
  final String lastSeen;

  const DeviceModel({
    required this.id,
    required this.tenant,
    required this.os,
    required this.ip,
    required this.version,
    required this.status,
    required this.lastSeen,
  });

  DeviceModel copyWith({
    String? id,
    String? tenant,
    String? os,
    String? ip,
    String? version,
    String? status,
    String? lastSeen,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      tenant: tenant ?? this.tenant,
      os: os ?? this.os,
      ip: ip ?? this.ip,
      version: version ?? this.version,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
