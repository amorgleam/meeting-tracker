import 'dart:convert';

class TaskItem {
  final String id;
  final String meetingId;
  final String? parentTaskId; // Null for Main Tasks, non-null for Subtasks
  final String title;
  final String description;
  final String status; // 'Pending', 'In Progress', 'Completed', 'Eliminated'
  final List<String> assignedMemberIds;
  final String note;
  final DateTime originMeetingDate; // Track carry forward: "carried from <date>"
  final DateTime? deadline; // Target completion deadline
  final bool isOverridden;
  final String? overrideReason;
  final String? overrideBy;
  final DateTime? overrideAt;
  final int orderIndex;
  final DateTime createdAt; // Task initiate date (formal entry into docket)
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final String deviceId;

  TaskItem({
    required this.id,
    required this.meetingId,
    this.parentTaskId,
    required this.title,
    this.description = '',
    this.status = 'Pending',
    this.assignedMemberIds = const [],
    this.note = '',
    required this.originMeetingDate,
    this.deadline,
    this.isOverridden = false,
    this.overrideReason,
    this.overrideBy,
    this.overrideAt,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deviceId = 'local',
  });

  bool get isMainTask => parentTaskId == null;
  bool get isSubtask => parentTaskId != null;
  bool get hasDeadline => deadline != null;

  DateTime get initiateDate => createdAt;

  bool get isOverdue {
    if (deadline == null) return false;
    if (status == 'Completed' || status == 'Eliminated') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return today.isAfter(due);
  }

  bool get isDueToday {
    if (deadline == null) return false;
    if (status == 'Completed' || status == 'Eliminated') return false;
    final now = DateTime.now();
    return deadline!.year == now.year && deadline!.month == now.month && deadline!.day == now.day;
  }

  int? get daysUntilDeadline {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return due.difference(today).inDays;
  }

  TaskItem copyWith({
    String? id,
    String? meetingId,
    String? parentTaskId,
    String? title,
    String? description,
    String? status,
    List<String>? assignedMemberIds,
    String? note,
    DateTime? originMeetingDate,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? isOverridden,
    String? overrideReason,
    String? overrideBy,
    DateTime? overrideAt,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
  }) {
    return TaskItem(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedMemberIds: assignedMemberIds ?? this.assignedMemberIds,
      note: note ?? this.note,
      originMeetingDate: originMeetingDate ?? this.originMeetingDate,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      isOverridden: isOverridden ?? this.isOverridden,
      overrideReason: overrideReason ?? this.overrideReason,
      overrideBy: overrideBy ?? this.overrideBy,
      overrideAt: overrideAt ?? this.overrideAt,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'parent_task_id': parentTaskId,
      'title': title,
      'description': description,
      'status': status,
      'assigned_member_ids': assignedMemberIds,
      'note': note,
      'origin_meeting_date': originMeetingDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'is_overridden': isOverridden,
      'override_reason': overrideReason,
      'override_by': overrideBy,
      'override_at': overrideAt?.toIso8601String(),
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'is_deleted': isDeleted,
      'device_id': deviceId,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    List<String> members = [];
    if (json['assigned_member_ids'] != null) {
      if (json['assigned_member_ids'] is List) {
        members = (json['assigned_member_ids'] as List).map((e) => e.toString()).toList();
      } else if (json['assigned_member_ids'] is String) {
        try {
          final decoded = jsonDecode(json['assigned_member_ids']);
          if (decoded is List) {
            members = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    return TaskItem(
      id: json['id'] as String,
      meetingId: json['meeting_id'] as String,
      parentTaskId: json['parent_task_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      assignedMemberIds: members,
      note: json['note'] as String? ?? '',
      originMeetingDate: DateTime.parse(json['origin_meeting_date'] as String),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      isOverridden: (json['is_overridden'] as bool?) ?? false,
      overrideReason: json['override_reason'] as String?,
      overrideBy: json['override_by'] as String?,
      overrideAt: json['override_at'] != null ? DateTime.parse(json['override_at'] as String) : null,
      orderIndex: (json['order_index'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      version: (json['version'] as int?) ?? 1,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      deviceId: json['device_id'] as String? ?? 'local',
    );
  }
}
