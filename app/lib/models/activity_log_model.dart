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
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      meetingId: json['meeting_id'] as String?,
      taskTitle: json['task_title'] as String? ?? 'Untitled Task',
      oldState: json['old_state'] as String? ?? '',
      newState: json['new_state'] as String? ?? '',
      userId: json['user_id'] as String? ?? 'system',
      userName: json['user_name'] as String? ?? 'System',
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String? ?? '',
      isOverride: (json['is_override'] as bool?) ?? false,
      overrideReason: json['override_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      version: (json['version'] as int?) ?? 1,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      deviceId: json['device_id'] as String? ?? 'local',
    );
  }
}
