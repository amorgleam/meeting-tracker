import 'model_helpers.dart';

class ActivityLog {
  final String id;
  final String taskId;
  final String? meetingId;
  final String taskTitle;
  final String oldState;
  final String newState;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String note;
  final bool isOverride;
  final String? overrideReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final String deviceId;

  ActivityLog({
    required this.id,
    required this.taskId,
    this.meetingId,
    required this.taskTitle,
    required this.oldState,
    required this.newState,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.note = '',
    this.isOverride = false,
    this.overrideReason,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deviceId = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'meeting_id': meetingId,
      'task_title': taskTitle,
      'old_state': oldState,
      'new_state': newState,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'is_override': isOverride,
      'override_reason': overrideReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'is_deleted': isDeleted,
      'device_id': deviceId,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      meetingId: json['meeting_id']?.toString(),
      taskTitle: json['task_title']?.toString() ?? 'Untitled Task',
      oldState: json['old_state']?.toString() ?? '',
      newState: json['new_state']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? 'system',
      userName: json['user_name']?.toString() ?? 'System',
      timestamp: parseIsoDate(json['timestamp']),
      note: json['note']?.toString() ?? '',
      isOverride: parseSqlBool(json['is_override'], defaultValue: false),
      overrideReason: json['override_reason']?.toString(),
      createdAt: parseIsoDate(json['created_at']),
      updatedAt: parseIsoDate(json['updated_at']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      isDeleted: parseSqlBool(json['is_deleted'], defaultValue: false),
      deviceId: json['device_id']?.toString() ?? 'local',
    );
  }
}
