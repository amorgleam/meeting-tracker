import '../models/task_model.dart';
import '../models/app_settings_model.dart';

class CompletionRuleValidationResult {
  final bool isAllowed;
  final String? message;
  final List<TaskItem> openSubtasks;
  final bool canOverride;

  const CompletionRuleValidationResult({
    required this.isAllowed,
    this.message,
    this.openSubtasks = const [],
    this.canOverride = false,
  });
}

class CompletionRules {
  /// Validates whether a Main Task is eligible to be set to "Completed".
  /// 
  /// [mode] Mode A: Strict (default), Mode B: Relaxed
  /// [userRole] 'Admin', 'Secretary', or 'Viewer'
  static CompletionRuleValidationResult validateCompletion({
    required TaskItem mainTask,
    required List<TaskItem> subtasks,
    required CompletionRuleMode mode,
    required String userRole,
  }) {
    // If the task has no subtasks, it can always be marked Completed
    if (subtasks.isEmpty) {
      return const CompletionRuleValidationResult(isAllowed: true);
    }

    final bool userCanOverride = canUserOverride(userRole);

    if (mode == CompletionRuleMode.strict) {
      // Mode A "Strict": All subtasks must be Completed
      final openSubtasks = subtasks.where((s) => s.status != 'Completed').toList();
      
      if (openSubtasks.isNotEmpty) {
        final subtaskNames = openSubtasks.map((s) => "• ${s.title} (${s.status})").join('\n');
        return CompletionRuleValidationResult(
          isAllowed: false,
          openSubtasks: openSubtasks,
          canOverride: userCanOverride,
          message: 'Mode A (Strict Rule): A main task can only be Completed when ALL subtasks are Completed.\n\n'
              'The following ${openSubtasks.length} subtask(s) are still incomplete:\n$subtaskNames',
        );
      }
      return const CompletionRuleValidationResult(isAllowed: true);
    } else {
      // Mode B "Relaxed": Allowed when every subtask is Completed or Eliminated, with at least one Completed.
      final pendingOrInProgress = subtasks
          .where((s) => s.status == 'Pending' || s.status == 'In Progress')
          .toList();
      final completedCount = subtasks.where((s) => s.status == 'Completed').length;

      if (pendingOrInProgress.isNotEmpty) {
        final subtaskNames = pendingOrInProgress.map((s) => "• ${s.title} (${s.status})").join('\n');
        return CompletionRuleValidationResult(
          isAllowed: false,
          openSubtasks: pendingOrInProgress,
          canOverride: userCanOverride,
          message: 'Mode B (Relaxed Rule): All subtasks must be either Completed or Eliminated.\n\n'
              'The following ${pendingOrInProgress.length} subtask(s) remain open:\n$subtaskNames',
        );
      }

      if (completedCount == 0) {
        return CompletionRuleValidationResult(
          isAllowed: false,
          openSubtasks: subtasks,
          canOverride: userCanOverride,
          message: 'Mode B (Relaxed Rule): At least one subtask must be Completed (cannot complete if all subtasks were eliminated).',
        );
      }

      return const CompletionRuleValidationResult(isAllowed: true);
    }
  }

  /// Determines if current role has executive authorization to force-complete.
  static bool canUserOverride(String role) {
    final normalized = role.toLowerCase().trim();
    return normalized == 'admin' || normalized == 'secretary';
  }
}
