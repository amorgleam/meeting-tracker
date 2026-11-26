class ConnectedDevice {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String userName;
  final String userRole;
  final String ip;
  final DateTime? connectedAt;
  final DateTime? lastSeenAt;
  final String transport;
  final bool online;

  ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.userName,
    required this.userRole,
    required this.ip,
    this.connectedAt,
    this.lastSeenAt,
    this.transport = 'websocket',
    this.online = true,
  });

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      deviceId: json['device_id']?.toString() ?? 'unknown',
      deviceName: json['device_name']?.toString() ?? 'Connected Device',
      platform: json['platform']?.toString() ?? 'Unknown',
      userName: json['user_name']?.toString() ?? 'Member',
      userRole: json['user_role']?.toString() ?? 'Admin',
      ip: json['ip']?.toString() ?? 'unknown',
      connectedAt: json['connected_at'] != null
          ? DateTime.tryParse(json['connected_at'].toString())
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      transport: json['transport']?.toString() ?? 'websocket',
      online: json['online'] == null ? true : (json['online'] == true || json['online'] == 1),
    );
  }
}
