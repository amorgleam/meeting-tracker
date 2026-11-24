import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../database/local_database.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';

enum SyncStatus { idle, syncing, synced, offline, error }

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  String _serverBaseUrl = 'http://localhost:3000';
  String _deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
  String? _authToken;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.idle);
  VoidCallback? onDataChanged;

  WebSocketChannel? _wsChannel;
  Timer? _wsReconnectTimer;
  Timer? _autoSyncTimer;
  bool _isSyncing = false;

  void configure({
    required String serverBaseUrl,
    required String deviceId,
    String? authToken,
    VoidCallback? onDataChangedCallback,
  }) {
    _serverBaseUrl = serverBaseUrl.replaceAll(RegExp(r'/+$'), '');
    _deviceId = deviceId;
    _authToken = authToken;
    onDataChanged = onDataChangedCallback;
  }

  void startPeriodicSync({Duration interval = const Duration(seconds: 15)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) => sync());
    connectWebSocket();
  }

  void stopPeriodicSync() {
    _autoSyncTimer?.cancel();
    disconnectWebSocket();
  }

  /// Full push/pull synchronization cycle
  Future<bool> sync() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      // 1. Push pending offline outbox items
      final outboxItems = LocalDatabase.instance.getPendingOutbox();
      if (outboxItems.isNotEmpty) {
        final pushSuccess = await _pushOutbox(outboxItems);
        if (!pushSuccess) {
          _updateStatus(SyncStatus.offline);
          _isSyncing = false;
          return false;
        }
      }

      // 2. Pull server updates since last sync token
      final pullSuccess = await _pullUpdates();
      if (!pullSuccess) {
        _updateStatus(SyncStatus.offline);
        _isSyncing = false;
        return false;
      }

      _updateStatus(SyncStatus.synced);
      _isSyncing = false;
      return true;
    } catch (e) {
      debugPrint('[SYNC SERVICE EXCEPTION] $e');
      _updateStatus(SyncStatus.offline);
      _isSyncing = false;
      return false;
    }
  }

  Future<bool> _pushOutbox(List<Map<String, dynamic>> items) async {
    try {
      final pushUrl = Uri.parse('$_serverBaseUrl/api/v1/sync/push');
      final mutations = items.map((item) {
        return {
          'id': item['id'],
          'entity_type': item['entity_type'],
          'entity_id': item['entity_id'],
          'operation': item['operation'],
          'payload': jsonDecode(item['payload'] as String),
        };
      }).toList();

      final response = await http.post(
        pushUrl,
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'device_id': _deviceId,
          'mutations': mutations,
        }),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        // Clear pushed items from local outbox
        for (final item in items) {
          LocalDatabase.instance.removeOutboxItem(item['id'] as String);
        }
        return true;
      } else {
        debugPrint('[SYNC PUSH REJECTED] Status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[SYNC PUSH NETWORK ERROR] $e');
      return false;
    }
  }

  Future<bool> _pullUpdates() async {
    try {
      final lastToken = LocalDatabase.instance.getSyncToken();
      final queryParams = <String, String>{
        'device_id': _deviceId,
        if (lastToken != null) 'since': lastToken,
      };

      final pullUrl = Uri.parse('$_serverBaseUrl/api/v1/sync/pull').replace(queryParameters: queryParams);
      final response = await http.get(
        pullUrl,
        headers: {
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        bool hasChanges = false;

        // Apply Members
        if (data['members'] != null) {
          for (final raw in (data['members'] as List)) {
            final m = Member.fromJson(Map<String, dynamic>.from(raw));
            LocalDatabase.instance.insertMember(m, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        // Apply Meetings
        if (data['meetings'] != null) {
          for (final raw in (data['meetings'] as List)) {
            final meet = Meeting.fromJson(Map<String, dynamic>.from(raw));
            LocalDatabase.instance.insertMeeting(meet, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        // Apply Tasks
        if (data['tasks'] != null) {
          for (final raw in (data['tasks'] as List)) {
            final t = TaskItem.fromJson(Map<String, dynamic>.from(raw));
            LocalDatabase.instance.insertTask(t, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        // Apply Activity Logs
        if (data['activity_logs'] != null) {
          for (final raw in (data['activity_logs'] as List)) {
            final a = ActivityLog.fromJson(Map<String, dynamic>.from(raw));
            LocalDatabase.instance.insertActivityLog(a, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        // Update sync token
        if (data['sync_token'] != null) {
          LocalDatabase.instance.setSyncToken(data['sync_token'] as String);
        }

        if (hasChanges && onDataChanged != null) {
          onDataChanged!();
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SYNC PULL NETWORK ERROR] $e');
      return false;
    }
  }

  // --- Realtime WebSocket Gateway Connection ---
  void connectWebSocket() {
    disconnectWebSocket();

    final wsUri = Uri.parse('${_serverBaseUrl.replaceFirst('http', 'ws')}/ws');
    try {
      _wsChannel = WebSocketChannel.connect(wsUri);
      _wsChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (err) {
          debugPrint('[WS STREAM ERROR] $err');
          _scheduleWsReconnect();
        },
        onDone: () {
          debugPrint('[WS STREAM CLOSED]');
          _scheduleWsReconnect();
        },
      );
    } catch (e) {
      debugPrint('[WS CONNECTION FAILED] $e');
      _scheduleWsReconnect();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final parsed = jsonDecode(message.toString()) as Map<String, dynamic>;
      final event = parsed['event'] as String?;

      if (event == 'entity_updated') {
        final entityData = parsed['data'] as Map<String, dynamic>?;
        if (entityData != null) {
          final entityType = entityData['entity_type'] as String?;
          final payload = entityData['payload'] as Map<String, dynamic>?;

          if (payload != null) {
            if (entityType == 'task') {
              final task = TaskItem.fromJson(payload);
              LocalDatabase.instance.insertTask(task, enqueueOutbox: false);
            } else if (entityType == 'meeting') {
              final meeting = Meeting.fromJson(payload);
              LocalDatabase.instance.insertMeeting(meeting, enqueueOutbox: false);
            } else if (entityType == 'member') {
              final member = Member.fromJson(payload);
              LocalDatabase.instance.insertMember(member, enqueueOutbox: false);
            } else if (entityType == 'activity_log') {
              final log = ActivityLog.fromJson(payload);
              LocalDatabase.instance.insertActivityLog(log, enqueueOutbox: false);
            }

            if (onDataChanged != null) {
              onDataChanged!();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[WS MESSAGE PARSE ERROR] $e');
    }
  }

  void _scheduleWsReconnect() {
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(const Duration(seconds: 10), () {
      connectWebSocket();
    });
  }

  void disconnectWebSocket() {
    _wsReconnectTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    statusNotifier.value = newStatus;
  }
}
