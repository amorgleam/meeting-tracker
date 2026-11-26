import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';
import '../models/app_settings_model.dart';
import 'db_backend_interface.dart';
import 'db_backend_web.dart' if (dart.library.io) 'db_backend_io.dart';

class LocalDatabase {
  static LocalDatabase? _instance;
  static LocalDatabase get instance => _instance ??= LocalDatabase._();

  final LocalDbBackend _backend = createDbBackend();
  bool _isReady = false;
  bool get isReady => _isReady;

  LocalDatabase._();

  Future<void> init() async {
    if (_isReady) return;
    await _backend.init();
    _isReady = true;
  }

  // --- Member Persistence ---
  void insertMember(Member member, {bool enqueueOutbox = true}) {
    if (!_isReady) return;
    _backend.insertMember(member, enqueueOutbox: enqueueOutbox);
  }

  List<Member> getMembers() {
    if (!_isReady) return [];
    return _backend.getMembers();
  }

  // --- Meeting Persistence ---
  void insertMeeting(Meeting meeting, {bool enqueueOutbox = true}) {
    if (!_isReady) return;
    _backend.insertMeeting(meeting, enqueueOutbox: enqueueOutbox);
  }

  List<Meeting> getMeetings() {
    if (!_isReady) return [];
    return _backend.getMeetings();
  }

  // --- Task Persistence ---
  void insertTask(TaskItem task, {bool enqueueOutbox = true}) {
    if (!_isReady) return;
    _backend.insertTask(task, enqueueOutbox: enqueueOutbox);
  }

  List<TaskItem> getTasks() {
    if (!_isReady) return [];
    return _backend.getTasks();
  }

  // --- Activity Log Persistence ---
  void insertActivityLog(ActivityLog log, {bool enqueueOutbox = true}) {
    if (!_isReady) return;
    _backend.insertActivityLog(log, enqueueOutbox: enqueueOutbox);
  }

  List<ActivityLog> getActivityLogs() {
    if (!_isReady) return [];
    return _backend.getActivityLogs();
  }

  // --- Outbox Queue Operations ---
  List<Map<String, dynamic>> getPendingOutbox() {
    if (!_isReady) return [];
    return _backend.getPendingOutbox();
  }

  void removeOutboxItem(String id) {
    if (!_isReady) return;
    _backend.removeOutboxItem(id);
  }

  void incrementOutboxAttempts(String id, String error) {
    if (!_isReady) return;
    _backend.incrementOutboxAttempts(id, error);
  }

  // --- Sync Tokens, Device Identity & AppSettings Persistence ---
  String? getSyncToken() {
    if (!_isReady) return null;
    return _backend.getMetadata('last_sync_token');
  }

  void setSyncToken(String token) {
    if (!_isReady) return;
    _backend.setMetadata('last_sync_token', token);
  }

  String getOrCreateDeviceId() {
    if (!_isReady) return 'local-device';
    final existing = _backend.getMetadata('unique_device_id');
    if (existing != null && existing.isNotEmpty) return existing;

    final prefix = kIsWeb
        ? 'web'
        : _backend.getPlatformLabel().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final generated = '$prefix-${const Uuid().v4().substring(0, 8)}';
    _backend.setMetadata('unique_device_id', generated);
    return generated;
  }

  String getPlatformLabel() => kIsWeb ? 'Web' : _backend.getPlatformLabel();

  AppSettings? loadSettings() {
    if (!_isReady) return null;
    final raw = _backend.getMetadata('app_settings_json');
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (e) {
      debugPrint('Failed to parse saved settings: $e');
      return null;
    }
  }

  void saveSettings(AppSettings settings) {
    if (!_isReady) return;
    _backend.setMetadata('app_settings_json', jsonEncode(settings.toJson()));
  }

  void close() {
    _backend.close();
    _isReady = false;
  }
}
