import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_tracker/models/member_model.dart';
import 'package:meeting_tracker/models/meeting_model.dart';
import 'package:meeting_tracker/models/task_model.dart';
import 'package:meeting_tracker/models/activity_log_model.dart';
import 'package:meeting_tracker/models/app_settings_model.dart';

void main() {
  group('Persistence & SQLite Row Serialization Tests', () {
    test('Models safely deserialize SQLite INTEGER (0/1) booleans and JSON strings', () {
      final now = DateTime(2026, 11, 25, 10, 30).toIso8601String();

      final memberFromSqlite = Member.fromJson({
        'id': 'mem-sql-1',
        'name': 'Sarah Jenkins',
        'email': 'sarah@institution.gov',
        'designation': 'Legal Counsel',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
        'version': 2,
        'is_deleted': 0,
        'device_id': 'win-1234',
      });
      expect(memberFromSqlite.isActive, isTrue);
      expect(memberFromSqlite.isDeleted, isFalse);

      final meetingFromSqlite = Meeting.fromJson({
        'id': 'meet-sql-1',
        'meeting_date': now,
        'title': 'Special Council',
        'attendee_member_ids': '["mem-sql-1"]',
        'status': 'In Progress',
        'notes': 'Opening session',
        'created_at': now,
        'updated_at': now,
        'version': 1,
        'is_deleted': 0,
        'device_id': 'win-1234',
      });
      expect(meetingFromSqlite.attendeeMemberIds, ['mem-sql-1']);
      expect(meetingFromSqlite.isDeleted, isFalse);

      final taskFromSqlite = TaskItem.fromJson({
        'id': 'task-sql-1',
        'meeting_id': 'meet-sql-1',
        'parent_task_id': null,
        'title': 'Verify Registry Backup',
        'description': 'Quarterly drill',
        'status': 'Completed',
        'assigned_member_ids': '["mem-sql-1"]',
        'note': 'Verified',
        'origin_meeting_date': now,
        'deadline': now,
        'is_overridden': 1,
        'override_reason': 'Executive Sign-off',
        'override_by': 'Admin',
        'override_at': now,
        'order_index': 0,
        'created_at': now,
        'updated_at': now,
        'version': 3,
        'is_deleted': 0,
        'device_id': 'win-1234',
      });
      expect(taskFromSqlite.isOverridden, isTrue);
      expect(taskFromSqlite.isDeleted, isFalse);
      expect(taskFromSqlite.assignedMemberIds, ['mem-sql-1']);

      final logFromSqlite = ActivityLog.fromJson({
        'id': 'log-sql-1',
        'task_id': 'task-sql-1',
        'meeting_id': 'meet-sql-1',
        'task_title': 'Verify Registry Backup',
        'old_state': 'Pending',
        'new_state': 'Completed',
        'user_id': 'user-admin',
        'user_name': 'Admin',
        'timestamp': now,
        'note': 'Forced completion',
        'is_override': 1,
        'override_reason': 'Executive Sign-off',
        'created_at': now,
        'updated_at': now,
        'version': 1,
        'is_deleted': 0,
        'device_id': 'win-1234',
      });
      expect(logFromSqlite.isOverride, isTrue);
      expect(logFromSqlite.isDeleted, isFalse);
    });

    test('AppSettings serializes and restores Render URL, theme colors, and letterhead cleanly', () {
      final original = AppSettings(
        completionRule: CompletionRuleMode.relaxed,
        serverUrl: 'https://meeting-tracker-api-kb6s.onrender.com',
        userRole: 'Secretary',
        deviceId: 'win-abcd1234',
        enableLetterhead: true,
        letterheadBase64: 'AAAA',
        primaryColorHex: '#5B1E31',
        accentColorHex: '#C49A45',
      );
      final restored = AppSettings.fromJson(original.toJson());
      expect(restored.serverUrl, 'https://meeting-tracker-api-kb6s.onrender.com');
      expect(restored.completionRule, CompletionRuleMode.relaxed);
      expect(restored.enableLetterhead, isTrue);
      expect(restored.primaryColorHex, '#5B1E31');
      expect(restored.deviceId, 'win-abcd1234');
    });
  });
}
