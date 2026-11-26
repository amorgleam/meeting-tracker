import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';
import 'db_backend_interface.dart';

LocalDbBackend createDbBackend() => LocalDbBackendIo();

class LocalDbBackendIo implements LocalDbBackend {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(dir.path, 'meeting_tracker_offline.db');
    _db = sqlite3.open(dbPath);
    _createTables();
  }

  void _createTables() {
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        designation TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS meetings (
        id TEXT PRIMARY KEY,
        meeting_date TEXT NOT NULL,
        title TEXT,
        attendee_member_ids TEXT,
        status TEXT NOT NULL DEFAULT 'In Progress',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        meeting_id TEXT NOT NULL,
        parent_task_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'Pending',
        assigned_member_ids TEXT,
        note TEXT,
        origin_meeting_date TEXT NOT NULL,
        deadline TEXT,
        is_overridden INTEGER NOT NULL DEFAULT 0,
        override_reason TEXT,
        override_by TEXT,
        override_at TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        meeting_id TEXT,
        task_title TEXT NOT NULL,
        old_state TEXT NOT NULL,
        new_state TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT,
        is_override INTEGER NOT NULL DEFAULT 0,
        override_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS outbox_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    try {
      _db!.execute('ALTER TABLE tasks ADD COLUMN deadline TEXT;');
    } catch (_) {}
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_meeting ON tasks(meeting_id);');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_parent ON tasks(parent_task_id);');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_activity_meeting ON activity_logs(meeting_id);');
  }

  @override
  void insertMember(Member member, {bool enqueueOutbox = true}) {
    if (_db == null) return;
    final stmt = _db!.prepare('''
      INSERT OR REPLACE INTO members (id, name, email, designation, is_active, created_at, updated_at, version, is_deleted, device_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    stmt.execute([
      member.id,
      member.name,
      member.email,
      member.designation,
      member.isActive ? 1 : 0,
      member.createdAt.toIso8601String(),
      member.updatedAt.toIso8601String(),
      member.version,
      member.isDeleted ? 1 : 0,
      member.deviceId,
    ]);
    stmt.dispose();

    if (enqueueOutbox) {
      _enqueueOutbox('member', member.id, 'UPSERT', member.toJson());
    }
  }

  @override
  List<Member> getMembers() {
    if (_db == null) return [];
    final results = _db!.select('SELECT * FROM members WHERE is_deleted = 0 ORDER BY name ASC;');
    return results.map((r) => Member.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  @override
  void insertMeeting(Meeting meeting, {bool enqueueOutbox = true}) {
    if (_db == null) return;
    final stmt = _db!.prepare('''
      INSERT OR REPLACE INTO meetings (id, meeting_date, title, attendee_member_ids, status, notes, created_at, updated_at, version, is_deleted, device_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    stmt.execute([
      meeting.id,
      meeting.meetingDate.toIso8601String(),
      meeting.title,
      jsonEncode(meeting.attendeeMemberIds),
      meeting.status,
      meeting.notes,
      meeting.createdAt.toIso8601String(),
      meeting.updatedAt.toIso8601String(),
      meeting.version,
      meeting.isDeleted ? 1 : 0,
      meeting.deviceId,
    ]);
    stmt.dispose();

    if (enqueueOutbox) {
      _enqueueOutbox('meeting', meeting.id, 'UPSERT', meeting.toJson());
    }
  }

  @override
  List<Meeting> getMeetings() {
    if (_db == null) return [];
    final results = _db!.select('SELECT * FROM meetings WHERE is_deleted = 0 ORDER BY meeting_date DESC;');
    return results.map((r) => Meeting.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  @override
  void insertTask(TaskItem task, {bool enqueueOutbox = true}) {
    if (_db == null) return;
    final stmt = _db!.prepare('''
      INSERT OR REPLACE INTO tasks (
        id, meeting_id, parent_task_id, title, description, status,
        assigned_member_ids, note, origin_meeting_date, deadline, is_overridden,
        override_reason, override_by, override_at, order_index,
        created_at, updated_at, version, is_deleted, device_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    stmt.execute([
      task.id,
      task.meetingId,
      task.parentTaskId,
      task.title,
      task.description,
      task.status,
      jsonEncode(task.assignedMemberIds),
      task.note,
      task.originMeetingDate.toIso8601String(),
      task.deadline?.toIso8601String(),
      task.isOverridden ? 1 : 0,
      task.overrideReason,
      task.overrideBy,
      task.overrideAt?.toIso8601String(),
      task.orderIndex,
      task.createdAt.toIso8601String(),
      task.updatedAt.toIso8601String(),
      task.version,
      task.isDeleted ? 1 : 0,
      task.deviceId,
    ]);
    stmt.dispose();

    if (enqueueOutbox) {
      _enqueueOutbox('task', task.id, 'UPSERT', task.toJson());
    }
  }

  @override
  List<TaskItem> getTasks() {
    if (_db == null) return [];
    final results = _db!.select('SELECT * FROM tasks WHERE is_deleted = 0 ORDER BY order_index ASC, created_at ASC;');
    return results.map((r) => TaskItem.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  @override
  void insertActivityLog(ActivityLog log, {bool enqueueOutbox = true}) {
    if (_db == null) return;
    final stmt = _db!.prepare('''
      INSERT OR REPLACE INTO activity_logs (
        id, task_id, meeting_id, task_title, old_state, new_state,
        user_id, user_name, timestamp, note, is_override, override_reason,
        created_at, updated_at, version, is_deleted, device_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    stmt.execute([
      log.id,
      log.taskId,
      log.meetingId,
      log.taskTitle,
      log.oldState,
      log.newState,
      log.userId,
      log.userName,
      log.timestamp.toIso8601String(),
      log.note,
      log.isOverride ? 1 : 0,
      log.overrideReason,
      log.createdAt.toIso8601String(),
      log.updatedAt.toIso8601String(),
      log.version,
      log.isDeleted ? 1 : 0,
      log.deviceId,
    ]);
    stmt.dispose();

    if (enqueueOutbox) {
      _enqueueOutbox('activity_log', log.id, 'INSERT', log.toJson());
    }
  }

  @override
  List<ActivityLog> getActivityLogs() {
    if (_db == null) return [];
    final results = _db!.select('SELECT * FROM activity_logs ORDER BY timestamp DESC;');
    return results.map((r) => ActivityLog.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  void _enqueueOutbox(String entityType, String entityId, String op, Map<String, dynamic> payload) {
    if (_db == null) return;
    final now = DateTime.now().toIso8601String();
    final outboxId = '${entityType}_${entityId}_${DateTime.now().microsecondsSinceEpoch}';
    final stmt = _db!.prepare('''
      INSERT INTO outbox_queue (id, entity_type, entity_id, operation, payload, created_at, attempts)
      VALUES (?, ?, ?, ?, ?, ?, 0);
    ''');
    stmt.execute([outboxId, entityType, entityId, op, jsonEncode(payload), now]);
    stmt.dispose();
  }

  @override
  List<Map<String, dynamic>> getPendingOutbox() {
    if (_db == null) return [];
    final results = _db!.select('SELECT * FROM outbox_queue ORDER BY created_at ASC LIMIT 100;');
    return results.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  void removeOutboxItem(String id) {
    if (_db == null) return;
    final stmt = _db!.prepare('DELETE FROM outbox_queue WHERE id = ?;');
    stmt.execute([id]);
    stmt.dispose();
  }

  @override
  void incrementOutboxAttempts(String id, String error) {
    if (_db == null) return;
    final stmt = _db!.prepare('UPDATE outbox_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?;');
    stmt.execute([error, id]);
    stmt.dispose();
  }

  @override
  String? getMetadata(String key) {
    if (_db == null) return null;
    final stmt = _db!.prepare('SELECT value FROM sync_metadata WHERE key = ?;');
    final results = stmt.select([key]);
    stmt.dispose();
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  @override
  void setMetadata(String key, String value) {
    if (_db == null) return;
    final stmt = _db!.prepare('INSERT OR REPLACE INTO sync_metadata (key, value) VALUES (?, ?);');
    stmt.execute([key, value]);
    stmt.dispose();
  }

  @override
  String getPlatformLabel() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Desktop/Mobile';
  }

  @override
  void close() {
    _db?.dispose();
    _db = null;
  }
}
