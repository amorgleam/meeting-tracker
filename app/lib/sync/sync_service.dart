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
import '../models/app_settings_model.dart';
import '../models/connected_device_model.dart';

enum SyncStatus { idle, syncing, synced, offline, error }

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  String _serverBaseUrl = AppSettings.defaultProductionServerUrl;
  String _deviceId = 'device-local';
  String _deviceName = 'Institutional Client';
  String _platform = kIsWeb ? 'Web' : 'Desktop';
  String _userName = 'Arthur Pendelton (Sec-Gen)';
  String _userRole = 'Admin';
  String? _authToken;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.idle);
  final ValueNotifier<List<ConnectedDevice>> connectedDevicesNotifier =
      ValueNotifier<List<ConnectedDevice>>([]);

  VoidCallback? onDataChanged;
  void Function(List<ConnectedDevice>)? onDevicesUpdated;

  WebSocketChannel? _wsChannel;
  Timer? _wsReconnectTimer;
  Timer? _autoSyncTimer;
  Timer? _debouncedSyncTimer;
  bool _isSyncing = false;

  void configure({
    required String serverBaseUrl,
    required String deviceId,
    String? deviceName,
    String? platform,
    String? userName,
    String? userRole,
    String? authToken,
    VoidCallback? onDataChangedCallback,
    void Function(List<ConnectedDevice>)? onDevicesUpdatedCallback,
  }) {
    final cleanedUrl = serverBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final urlChanged = cleanedUrl != _serverBaseUrl;

    _serverBaseUrl = cleanedUrl;
    _deviceId = deviceId;
    if (deviceName != null) _deviceName = deviceName;
    if (platform != null) _platform = platform;
    if (userName != null) _userName = userName;
    if (userRole != null) _userRole = userRole;
    _authToken = authToken;
    onDataChanged = onDataChangedCallback;
    onDevicesUpdated = onDevicesUpdatedCallback;

    if (urlChanged) {
      connectWebSocket();
    } else {
      _sendDeviceRegistration();
    }
  }

  void startPeriodicSync({Duration interval = const Duration(seconds: 15)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) => sync());
    connectWebSocket();
  }

  void stopPeriodicSync() {
    _autoSyncTimer?.cancel();
    _debouncedSyncTimer?.cancel();
    disconnectWebSocket();
  }

  /// Debounced immediate push/pull after user edits so changes hit the server rapidly
  void scheduleImmediateSync({Duration delay = const Duration(milliseconds: 500)}) {
    _debouncedSyncTimer?.cancel();
    _debouncedSyncTimer = Timer(delay, () => sync());
  }

  /// Full push/pull synchronization cycle + connected devices refresh
  Future<bool> sync() async {
    if (!LocalDatabase.instance.isReady) return false;
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

      // 3. Refresh connected devices list
      await fetchConnectedDevices();

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

  Map<String, String> _deviceHeaders({bool includeContentType = false}) {
    return {
      if (includeContentType) 'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      'X-Device-Id': _deviceId,
      'X-Device-Name': _deviceName,
      'X-Device-Platform': _platform,
      'X-User-Name': _userName,
      'X-User-Role': _userRole,
    };
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
        headers: _deviceHeaders(includeContentType: true),
        body: jsonEncode({
          'device_id': _deviceId,
          'device_name': _deviceName,
          'platform': _platform,
          'user_name': _userName,
          'user_role': _userRole,
          'mutations': mutations,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
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
        'device_name': _deviceName,
        'platform': _platform,
        'user_name': _userName,
        'user_role': _userRole,
        if (lastToken != null) 'since': lastToken,
      };

      final pullUrl = Uri.parse('$_serverBaseUrl/api/v1/sync/pull').replace(queryParameters: queryParams);
      final response = await http.get(
        pullUrl,
        headers: _deviceHeaders(),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        bool hasChanges = false;

        if (data['members'] != null) {
          for (final raw in (data['members'] as List)) {
            final m = Member.fromJson(Map<String, dynamic>.from(raw as Map));
            LocalDatabase.instance.insertMember(m, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        if (data['meetings'] != null) {
          for (final raw in (data['meetings'] as List)) {
            final meet = Meeting.fromJson(Map<String, dynamic>.from(raw as Map));
            LocalDatabase.instance.insertMeeting(meet, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        if (data['tasks'] != null) {
          for (final raw in (data['tasks'] as List)) {
            final t = TaskItem.fromJson(Map<String, dynamic>.from(raw as Map));
            LocalDatabase.instance.insertTask(t, enqueueOutbox: false);
            hasChanges = true;
          }
        }

        if (data['activity_logs'] != null) {
          for (final raw in (data['activity_logs'] as List)) {
            final a = ActivityLog.fromJson(Map<String, dynamic>.from(raw as Map));
            LocalDatabase.instance.insertActivityLog(a, enqueueOutbox: false);
            hasChanges = true;
          }
        }

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

  Future<List<ConnectedDevice>> fetchConnectedDevices() async {
    try {
      final url = Uri.parse('$_serverBaseUrl/api/v1/devices');
      final response = await http.get(url, headers: _deviceHeaders()).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = (data['devices'] as List?) ?? [];
        final parsed = rawList
            .map((e) => ConnectedDevice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _applyDevicesList(parsed);
        return parsed;
      }
    } catch (e) {
      debugPrint('[DEVICES FETCH ERROR] $e');
    }
    return connectedDevicesNotifier.value;
  }

  void _applyDevicesList(List<ConnectedDevice> list) {
    connectedDevicesNotifier.value = list;
    if (onDevicesUpdated != null) {
      onDevicesUpdated!(list);
    }
  }

  // --- Realtime WebSocket Gateway Connection ---
  void connectWebSocket() {
    disconnectWebSocket();
    if (_serverBaseUrl.isEmpty) return;

    try {
      final base = Uri.parse(_serverBaseUrl);
      final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
      final wsUri = base.replace(
        scheme: wsScheme,
        path: '/ws',
        queryParameters: {
          'device_id': _deviceId,
          'device_name': _deviceName,
          'platform': _platform,
          'user_name': _userName,
          'user_role': _userRole,
        },
      );

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
      _sendDeviceRegistration();
    } catch (e) {
      debugPrint('[WS CONNECTION FAILED] $e');
      _scheduleWsReconnect();
    }
  }

  void _sendDeviceRegistration() {
    if (_wsChannel == null) return;
    try {
      _wsChannel!.sink.add(jsonEncode({
        'event': 'register_device',
        'data': {
          'device_id': _deviceId,
          'device_name': _deviceName,
          'platform': _platform,
          'user_name': _userName,
          'user_role': _userRole,
        },
      }));
    } catch (_) {}
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final parsed = jsonDecode(message.toString()) as Map<String, dynamic>;
      final event = parsed['event'] as String?;

      if (event == 'connected') {
        final rawDevices = parsed['devices'] as List?;
        if (rawDevices != null) {
          _applyDevicesList(
            rawDevices
                .map((e) => ConnectedDevice.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
          );
        }
        return;
      }

      if (event == 'devices_updated') {
        final data = parsed['data'] as Map<String, dynamic>?;
        final rawDevices = data?['devices'] as List?;
        if (rawDevices != null) {
          _applyDevicesList(
            rawDevices
                .map((e) => ConnectedDevice.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
          );
        }
        return;
      }

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
