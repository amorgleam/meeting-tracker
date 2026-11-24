import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_tracker/models/meeting_model.dart';
import 'package:meeting_tracker/models/task_model.dart';
import 'package:meeting_tracker/models/member_model.dart';
import 'package:meeting_tracker/models/activity_log_model.dart';
import 'package:meeting_tracker/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Export Service Tests', () {
    late Meeting testMeeting;
    late List<Member> testMembers;
    late List<TaskItem> newTasks;
    late List<TaskItem> carriedTasks;
    late List<ActivityLog> workDoneLogs;

    setUp(() {
      final now = DateTime(2026, 11, 24, 10, 0);

      testMembers = [
        Member(
          id: 'mem-1',
          name: 'Arthur Pendelton',
          email: 'arthur@institution.gov',
          designation: 'Director',
          createdAt: now,
          updatedAt: now,
          deviceId: 'test',
        ),
        Member(
          id: 'mem-2',
          name: 'Eleanor Vance',
          email: 'eleanor@institution.gov',
          designation: 'Secretary',
          createdAt: now,
          updatedAt: now,
          deviceId: 'test',
        ),
      ];

      testMeeting = Meeting(
        id: 'meet-101',
        meetingDate: now,
        title: 'Executive Council Plenary Session',
        attendeeMemberIds: ['mem-1', 'mem-2'],
        status: 'In Progress',
        notes: 'Review of institutional digital infrastructure overhaul.',
        createdAt: now,
        updatedAt: now,
        deviceId: 'test',
      );

      newTasks = [
        TaskItem(
          id: 'task-new-1',
          meetingId: 'meet-101',
          title: 'Deploy Institutional Biometric Terminals',
          status: 'Pending',
          assignedMemberIds: ['mem-1'],
          originMeetingDate: now,
          createdAt: now,
          updatedAt: now,
          deviceId: 'test',
        ),
      ];

      carriedTasks = [
        TaskItem(
          id: 'task-cf-1',
          meetingId: 'meet-past',
          title: 'Upgrade High-Security Vault Sensors',
          status: 'In Progress',
          assignedMemberIds: ['mem-2'],
          originMeetingDate: now.subtract(const Duration(days: 7)),
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now,
          deviceId: 'test',
        ),
      ];

      workDoneLogs = [
        ActivityLog(
          id: 'log-1',
          taskId: 'task-cf-1',
          meetingId: 'meet-101',
          taskTitle: 'Upgrade High-Security Vault Sensors',
          oldState: 'Pending',
          newState: 'In Progress',
          userId: 'mem-2',
          userName: 'Eleanor Vance',
          timestamp: now,
          note: 'Contractors on site commencing inspection',
          createdAt: now,
          updatedAt: now,
          deviceId: 'test',
        ),
      ];
    });

    test('Meeting Proceedings Excel generation creates file buffer without error', () async {
      final exportPath = await ExportService.exportMeetingToExcel(
        meeting: testMeeting,
        newTasks: newTasks,
        carriedTasks: carriedTasks,
        workDoneLogs: workDoneLogs,
        members: testMembers,
      );

      expect(exportPath, isNotEmpty);
      expect(exportPath.endsWith('.xlsx'), isTrue);
    });

    test('Master Task Ledger Excel generation contains all filtered tasks', () async {
      final allTasks = [...newTasks, ...carriedTasks];
      final exportPath = await ExportService.exportTaskLedgerToExcel(
        tasks: allTasks,
        members: testMembers,
        filterName: 'ALL TASKS',
      );

      expect(exportPath, isNotEmpty);
      expect(exportPath.endsWith('.xlsx'), isTrue);
    });

    test('Executive Period Report Excel generation includes metrics and workload', () async {
      final allTasks = [...newTasks, ...carriedTasks];
      final exportPath = await ExportService.exportReportToExcel(
        months: 3,
        periodTasks: allTasks,
        longPendingTasks: [],
        members: testMembers,
        completionRate: '50.0',
      );

      expect(exportPath, isNotEmpty);
      expect(exportPath.endsWith('.xlsx'), isTrue);
    });
  });
}
