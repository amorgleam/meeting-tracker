import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_tracker/models/task_model.dart';
import 'package:meeting_tracker/models/app_settings_model.dart';
import 'package:meeting_tracker/rules/completion_rules.dart';

void main() {
  group('Completion Rules Engine Tests', () {
    final now = DateTime.now();

    final mainTask = TaskItem(
      id: 'main-1',
      meetingId: 'meet-1',
      title: 'Digitize Archive Records',
      originMeetingDate: now,
      createdAt: now,
      updatedAt: now,
    );

    test('Main task with no subtasks can always be completed in either mode', () {
      final resStrict = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [],
        mode: CompletionRuleMode.strict,
        userRole: 'Viewer',
      );
      expect(resStrict.isAllowed, isTrue);

      final resRelaxed = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [],
        mode: CompletionRuleMode.relaxed,
        userRole: 'Viewer',
      );
      expect(resRelaxed.isAllowed, isTrue);
    });

    test('Mode A (Strict): Blocked if any subtask is not Completed', () {
      final sub1 = TaskItem(
        id: 'sub-1',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Procure Scanners',
        status: 'Completed',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sub2 = TaskItem(
        id: 'sub-2',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Scan Index Dockets',
        status: 'In Progress',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [sub1, sub2],
        mode: CompletionRuleMode.strict,
        userRole: 'Viewer',
      );

      expect(result.isAllowed, isFalse);
      expect(result.openSubtasks.length, equals(1));
      expect(result.openSubtasks.first.title, equals('Scan Index Dockets'));
      expect(result.canOverride, isFalse); // Viewer cannot override
    });

    test('Mode A (Strict): Allowed when ALL subtasks are Completed', () {
      final sub1 = TaskItem(
        id: 'sub-1',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Procure Scanners',
        status: 'Completed',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sub2 = TaskItem(
        id: 'sub-2',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Scan Index Dockets',
        status: 'Completed',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [sub1, sub2],
        mode: CompletionRuleMode.strict,
        userRole: 'Viewer',
      );

      expect(result.isAllowed, isTrue);
    });

    test('Mode B (Relaxed): Blocked if any subtask is Pending or In Progress', () {
      final sub1 = TaskItem(
        id: 'sub-1',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Procure Scanners',
        status: 'Completed',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sub2 = TaskItem(
        id: 'sub-2',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Scan Index Dockets',
        status: 'Pending',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [sub1, sub2],
        mode: CompletionRuleMode.relaxed,
        userRole: 'Admin',
      );

      expect(result.isAllowed, isFalse);
      expect(result.canOverride, isTrue); // Admin can override
    });

    test('Mode B (Relaxed): Allowed when subtasks are Completed or Eliminated (with at least 1 Completed)', () {
      final sub1 = TaskItem(
        id: 'sub-1',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Procure Scanners',
        status: 'Completed',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sub2 = TaskItem(
        id: 'sub-2',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Legacy Microfiche Reader',
        status: 'Eliminated',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [sub1, sub2],
        mode: CompletionRuleMode.relaxed,
        userRole: 'Viewer',
      );

      expect(result.isAllowed, isTrue);
    });

    test('Mode B (Relaxed): Blocked if ALL subtasks are Eliminated (needs at least one completed)', () {
      final sub1 = TaskItem(
        id: 'sub-1',
        meetingId: 'meet-1',
        parentTaskId: mainTask.id,
        title: 'Procure Scanners',
        status: 'Eliminated',
        originMeetingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = CompletionRules.validateCompletion(
        mainTask: mainTask,
        subtasks: [sub1],
        mode: CompletionRuleMode.relaxed,
        userRole: 'Secretary',
      );

      expect(result.isAllowed, isFalse);
      expect(result.canOverride, isTrue); // Secretary can override
    });

    test('Executive Override Authorization: Admin & Secretary permitted, Viewer denied', () {
      expect(CompletionRules.canUserOverride('Admin'), isTrue);
      expect(CompletionRules.canUserOverride('admin'), isTrue);
      expect(CompletionRules.canUserOverride('Secretary'), isTrue);
      expect(CompletionRules.canUserOverride('secretary'), isTrue);
      expect(CompletionRules.canUserOverride('Viewer'), isFalse);
      expect(CompletionRules.canUserOverride('Guest'), isFalse);
    });
  });
}
