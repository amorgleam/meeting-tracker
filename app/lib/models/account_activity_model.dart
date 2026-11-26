import 'model_helpers.dart';

class AccountActivity {
  final String id;
  final String? actorUserId;
  final String actorEmail;
  final String actorName;
  final String actorRole;
  final String actionType;
  final String targetInfo;
  final String details;
  final String deviceId;
  final String platform;
  final String ipAddress;
  final DateTime timestamp;

  AccountActivity({
    required this.id,
    this.actorUserId,
    required this.actorEmail,
    required this.actorName,
    required this.actorRole,
    required this.actionType,
    this.targetInfo = '',
    this.details = '',
    this.deviceId = '',
    this.platform = '',
    this.ipAddress = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actor_user_id': actorUserId,
      'actor_email': actorEmail,
      'actor_name': actorName,
      'actor_role': actorRole,
      'action_type': actionType,
      'target_info': targetInfo,
      'details': details,
      'device_id': deviceId,
      'platform': platform,
      'ip_address': ipAddress,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AccountActivity.fromJson(Map<String, dynamic> json) {
    return AccountActivity(
      id: json['id'].toString(),
      actorUserId: json['actor_user_id']?.toString(),
      actorEmail: json['actor_email']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? 'System',
      actorRole: json['actor_role']?.toString() ?? 'USER',
      actionType: json['action_type']?.toString() ?? 'EVENT',
      targetInfo: json['target_info']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? '',
      timestamp: parseIsoDate(json['timestamp']),
    );
  }
}
