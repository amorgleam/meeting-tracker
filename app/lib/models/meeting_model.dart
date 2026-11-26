import 'model_helpers.dart';

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
    return Meeting(
      id: json['id'].toString(),
      meetingDate: parseIsoDate(json['meeting_date']),
      title: json['title']?.toString() ?? '',
      attendeeMemberIds: parseIdList(json['attendee_member_ids']),
      status: json['status']?.toString() ?? 'In Progress',
      notes: json['notes']?.toString() ?? '',
      createdAt: parseIsoDate(json['created_at']),
      updatedAt: parseIsoDate(json['updated_at']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      isDeleted: parseSqlBool(json['is_deleted'], defaultValue: false),
      deviceId: json['device_id']?.toString() ?? 'local',
    );
  }
}
