import 'dart:convert';

class Meeting {
  final String id;
  final DateTime meetingDate;
  final String title;
  final List<String> attendeeMemberIds;
  final String status; // 'In Progress', 'Adjourned'
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final String deviceId;

  Meeting({
    required this.id,
    required this.meetingDate,
    this.title = '',
    this.attendeeMemberIds = const [],
    this.status = 'In Progress',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deviceId = 'local',
  });

  Meeting copyWith({
    String? id,
    DateTime? meetingDate,
    String? title,
    List<String>? attendeeMemberIds,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
  }) {
    return Meeting(
      id: id ?? this.id,
      meetingDate: meetingDate ?? this.meetingDate,
      title: title ?? this.title,
      attendeeMemberIds: attendeeMemberIds ?? this.attendeeMemberIds,
      status: status ?? this.status,
      notes: notes ?? this.notes,
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
      'meeting_date': meetingDate.toIso8601String(),
      'title': title,
      'attendee_member_ids': attendeeMemberIds,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'is_deleted': isDeleted,
      'device_id': deviceId,
    };
  }

  factory Meeting.fromJson(Map<String, dynamic> json) {
    List<String> attendees = [];
    if (json['attendee_member_ids'] != null) {
      if (json['attendee_member_ids'] is List) {
        attendees = (json['attendee_member_ids'] as List).map((e) => e.toString()).toList();
      } else if (json['attendee_member_ids'] is String) {
        try {
          final decoded = jsonDecode(json['attendee_member_ids']);
          if (decoded is List) {
            attendees = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    return Meeting(
      id: json['id'] as String,
      meetingDate: DateTime.parse(json['meeting_date'] as String),
      title: json['title'] as String? ?? '',
      attendeeMemberIds: attendees,
      status: json['status'] as String? ?? 'In Progress',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      version: (json['version'] as int?) ?? 1,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      deviceId: json['device_id'] as String? ?? 'local',
    );
  }
}
