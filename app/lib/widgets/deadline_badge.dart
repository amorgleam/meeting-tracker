import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/institutional_theme.dart';

class DeadlineBadge extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTap;
  final bool showInitiateDate;

  const DeadlineBadge({
    super.key,
    required this.task,
    this.onTap,
    this.showInitiateDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final initiateStr = dateFormat.format(task.initiateDate);

    if (task.deadline == null) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showInitiateDate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: InstitutionalTheme.creamSurface,
                border: Border.all(color: InstitutionalTheme.borderLedger),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 11, color: InstitutionalTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'INITIATED: $initiateStr',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstitutionalTheme.textMuted),
                  ),
                ],
              ),
            ),
          if (onTap != null)
            InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: InstitutionalTheme.borderLedger, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm_add, size: 11, color: InstitutionalTheme.primaryNavy),
                    SizedBox(width: 3),
                    Text(
                      '+ Set Deadline',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    final deadlineStr = dateFormat.format(task.deadline!);
    final daysUntil = task.daysUntilDeadline!;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String label;

    if (task.status == 'Completed' || task.status == 'Eliminated') {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFCBD5E1);
      textColor = const Color(0xFF475569);
      icon = Icons.event_available;
      label = 'TARGET: $deadlineStr';
    } else if (task.isOverdue) {
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
      final overdueDays = -daysUntil;
      label = 'OVERDUE ($overdueDays days): $deadlineStr';
    } else if (task.isDueToday) {
      bgColor = const Color(0xFFFEF9C3);
      borderColor = const Color(0xFFFDE047);
      textColor = const Color(0xFF854D0E);
      icon = Icons.alarm;
      label = 'DUE TODAY: $deadlineStr';
    } else {
      bgColor = const Color(0xFFEDE9FE); // Subtle purple tint matching institutional theme
      borderColor = const Color(0xFFDDD6FE);
      textColor = const Color(0xFF6D28D9);
      icon = Icons.hourglass_top;
      label = 'DUE IN $daysUntil DAYS: $deadlineStr';
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showInitiateDate)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: InstitutionalTheme.creamSurface,
              border: Border.all(color: InstitutionalTheme.borderLedger),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range, size: 11, color: InstitutionalTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'INITIATED: $initiateStr',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstitutionalTheme.textMuted),
                ),
              ],
            ),
          ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.edit, size: 10, color: textColor.withOpacity(0.7)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
