import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'model_helpers.dart';

class UserAccount {
  final String id;
  final String email;
  final String username;
  final String name;
  final String role; // 'ADMIN', 'SECRETARY', 'MEMBER', 'VIEWER'
  final String? memberId;
  final bool isActive;
  final String? offlinePasswordHash;
  final DateTime updatedAt;

  UserAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.role,
    this.memberId,
    this.isActive = true,
    this.offlinePasswordHash,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  static String hashPasswordOffline(String emailOrId, String password) {
    final normalizedKey = emailOrId.trim().toLowerCase();
    final bytes = utf8.encode('mt_inst_salt_v1::$normalizedKey::$password');
    return sha256.convert(bytes).toString();
  }

  bool verifyPasswordOffline(String password) {
    if (offlinePasswordHash == null || offlinePasswordHash!.isEmpty) return false;
    return offlinePasswordHash == hashPasswordOffline(email, password);
  }

  UserAccount copyWith({
    String? id,
    String? email,
    String? username,
    String? name,
    String? role,
    String? memberId,
    bool? isActive,
    String? offlinePasswordHash,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      memberId: memberId ?? this.memberId,
      isActive: isActive ?? this.isActive,
      offlinePasswordHash: offlinePasswordHash ?? this.offlinePasswordHash,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'role': role,
      'member_id': memberId,
      'is_active': isActive,
      'offline_password_hash': offlinePasswordHash,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString() ?? '';
    final rawUsername = json['username']?.toString();
    return UserAccount(
      id: json['id'].toString(),
      email: email,
      username: (rawUsername != null && rawUsername.isNotEmpty)
          ? rawUsername
          : (email.contains('@') ? email.split('@').first : email),
      name: json['name']?.toString() ?? 'Institutional User',
      role: json['role']?.toString() ?? 'SECRETARY',
      memberId: json['member_id']?.toString(),
      isActive: parseSqlBool(json['is_active'], defaultValue: true),
      offlinePasswordHash: json['offline_password_hash']?.toString(),
      updatedAt: parseIsoDate(json['updated_at']),
    );
  }
}
