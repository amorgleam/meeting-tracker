import 'model_helpers.dart';

class Member {
  final String id;
  final String name;
  final String email;
  final String designation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final String deviceId;

  Member({
    required this.id,
    required this.name,
    this.email = '',
    this.designation = 'Member',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deviceId = 'local',
  });

  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? designation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      isActive: isActive ?? this.isActive,
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
      'name': name,
      'email': email,
      'designation': designation,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'is_deleted': isDeleted,
      'device_id': deviceId,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Unnamed Member',
      email: json['email']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Member',
      isActive: parseSqlBool(json['is_active'], defaultValue: true),
      createdAt: parseIsoDate(json['created_at']),
      updatedAt: parseIsoDate(json['updated_at']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      isDeleted: parseSqlBool(json['is_deleted'], defaultValue: false),
      deviceId: json['device_id']?.toString() ?? 'local',
    );
  }
}
