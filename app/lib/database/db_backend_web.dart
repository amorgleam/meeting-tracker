import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';
import 'db_backend_interface.dart';

LocalDbBackend createDbBackend() => LocalDbBackendWeb();

/// Browser-safe persistent offline storage backed by SharedPreferences (localStorage).
class LocalDbBackendWeb implements LocalDbBackend {
  SharedPreferences? _prefs;
  bool _initialized = false;

  final Map<String, Member> _members = {};
  final Map<String, Meeting> _meetings = {};
  final Map<String, TaskItem> _tasks = {};
  final Map<String, ActivityLog> _activityLogs = {};
  final List<Map<String, dynamic>> _outbox = [];
  final Map<String, String> _metadata = {};

  static const _kMembers = 'mt_web_members_v1';
  static const _kMeetings = 'mt_web_meetings_v1';
  static const _kTasks = 'mt_web_tasks_v1';
  static const _kLogs = 'mt_web_logs_v1';
  static const _kOutbox = 'mt_web_outbox_v1';
  static const _kMeta = 'mt_web_meta_v1';

  @override
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    _loadMap(_kMembers, (raw) {
      final m = Member.fromJson(raw);
      _members[m.id] = m;
    });
    _loadMap(_kMeetings, (raw) {
      final m = Meeting.fromJson(raw);
      _meetings[m.id] = m;
    });
    _loadMap(_kTasks, (raw) {
      final t = TaskItem.fromJson(raw);
      _tasks[t.id] = t;
    });
    _loadMap(_kLogs, (raw) {
      final l = ActivityLog.fromJson(raw);
      _activityLogs[l.id] = l;
    });

    final outboxRaw = _prefs?.getString(_kOutbox);
    if (outboxRaw != null && outboxRaw.isNotEmpty) {
      try {
        final list = jsonDecode(outboxRaw) as List;
        _outbox.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }

    final metaRaw = _prefs?.getString(_kMeta);
    if (metaRaw != null && metaRaw.isNotEmpty) {
      try {
        final map = jsonDecode(metaRaw) as Map;
        map.forEach((k, v) => _metadata[k.toString()] = v.toString());
      } catch (_) {}
    }

    _initialized = true;
  }

  void _loadMap(String key, void Function(Map<String, dynamic>) onEntry) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      for (final item in list) {
        onEntry(Map<String, dynamic>.from(item as Map));
      }
    } catch (_) {}
  }

  void _persist(String key, Object value) {
    if (_prefs == null) return;
    unawaited(_prefs!.setString(key, jsonEncode(value)));
  }

  @override
  void insertMember(Member member, {bool enqueueOutbox = true}) {
    _members[member.id] = member;
    _persist(_kMembers, _members.values.map((e) => e.toJson()).toList());
    if (enqueueOutbox) {
      _enqueueOutbox('member', member.id, 'UPSERT', member.toJson());
    }
  }

  @override
  List<Member> getMembers() {
    final list = _members.values.where((m) => !m.isDeleted).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  void insertMeeting(Meeting meeting, {bool enqueueOutbox = true}) {
    _meetings[meeting.id] = meeting;
    _persist(_kMeetings, _meetings.values.map((e) => e.toJson()).toList());
    if (enqueueOutbox) {
      _enqueueOutbox('meeting', meeting.id, 'UPSERT', meeting.toJson());
    }
  }

  @override
  List<Meeting> getMeetings() {
    final list = _meetings.values.where((m) => !m.isDeleted).toList();
    list.sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
    return list;
  }

  @override
  void insertTask(TaskItem task, {bool enqueueOutbox = true}) {
    _tasks[task.id] = task;
    _persist(_kTasks, _tasks.values.map((e) => e.toJson()).toList());
    if (enqueueOutbox) {
      _enqueueOutbox('task', task.id, 'UPSERT', task.toJson());
    }
  }

  @override
  List<TaskItem> getTasks() {
    final list = _tasks.values.where((t) => !t.isDeleted).toList();
    list.sort((a, b) {
      final idxCmp = a.orderIndex.compareTo(b.orderIndex);
      return idxCmp != 0 ? idxCmp : a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  void insertActivityLog(ActivityLog log, {bool enqueueOutbox = true}) {
    _activityLogs[log.id] = log;
    _persist(_kLogs, _activityLogs.values.map((e) => e.toJson()).toList());
    if (enqueueOutbox) {
      _enqueueOutbox('activity_log', log.id, 'INSERT', log.toJson());
    }
  }

  @override
  List<ActivityLog> getActivityLogs() {
    final list = _activityLogs.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  void _enqueueOutbox(String entityType, String entityId, String op, Map<String, dynamic> payload) {
    final now = DateTime.now().toIso8601String();
    final outboxId = '${entityType}_${entityId}_${DateTime.now().microsecondsSinceEpoch}';
    _outbox.add({
      'id': outboxId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': op,
      'payload': jsonEncode(payload),
      'created_at': now,
      'attempts': 0,
      'last_error': null,
    });
    _persist(_kOutbox, _outbox);
  }

  @override
  List<Map<String, dynamic>> getPendingOutbox() {
    return List<Map<String, dynamic>>.from(_outbox.take(100));
  }

  @override
  void removeOutboxItem(String id) {
    _outbox.removeWhere((item) => item['id'] == id);
    _persist(_kOutbox, _outbox);
  }

  @override
  void incrementOutboxAttempts(String id, String error) {
    for (final item in _outbox) {
      if (item['id'] == id) {
        item['attempts'] = ((item['attempts'] as int?) ?? 0) + 1;
        item['last_error'] = error;
      }
    }
    _persist(_kOutbox, _outbox);
  }

  @override
  String? getMetadata(String key) => _metadata[key];

  @override
  void setMetadata(String key, String value) {
    _metadata[key] = value;
    _persist(_kMeta, _metadata);
  }

  @override
  String getPlatformLabel() => 'Web';

  @override
  void close() {}
}
