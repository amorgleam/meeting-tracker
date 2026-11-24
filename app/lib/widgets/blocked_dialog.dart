import 'package:flutter/material.dart';
import '../theme/institutional_theme.dart';
import '../models/task_model.dart';
import '../widgets/status_chip.dart';

class BlockedDialog extends StatelessWidget {
  final TaskItem task;
  final String ruleExplanation;
  final List<TaskItem> openSubtasks;
  final bool canOverride;
  final VoidCallback? onTriggerOverride;

  const BlockedDialog({
    super.key,
    required this.task,
    required this.ruleExplanation,
    required this.openSubtasks,
    this.canOverride = false,
    this.onTriggerOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: InstitutionalTheme.creamCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: InstitutionalTheme.bgPending,
                    border: Border.all(color: InstitutionalTheme.statusPending, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    color: InstitutionalTheme.statusPending,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TASK COMPLETION PROTOCOL BLOCKED',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: InstitutionalTheme.primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Institutional Governance & Workflow Rule Compliance',
                        style: TextStyle(
                          fontSize: 12,
                          color: InstitutionalTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 14),
            Text(
              'Cannot mark "${task.title}" as Completed.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: InstitutionalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InstitutionalTheme.creamSurface,
                border: Border.all(color: InstitutionalTheme.borderLedger),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                ruleExplanation,
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: InstitutionalTheme.textBody),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'INCOMPLETE SUBTASKS (${openSubtasks.length}):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: InstitutionalTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: InstitutionalTheme.borderLedger),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: openSubtasks.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sub = openSubtasks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.subdirectory_arrow_right, size: 16, color: InstitutionalTheme.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: InstitutionalTheme.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(status: sub.status, isCompact: true),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canOverride)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: InstitutionalTheme.statusOverride,
                    ),
                    icon: const Icon(Icons.security, size: 18),
                    label: const Text('FORCE COMPLETE (OVERRIDE)...'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onTriggerOverride != null) {
                        onTriggerOverride!();
                      }
                    },
                  )
                else
                  const Text(
                    'Administrative override required to bypass.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: InstitutionalTheme.textMuted),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ACKNOWLEDGE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
