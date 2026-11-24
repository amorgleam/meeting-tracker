import 'package:flutter/material.dart';
import '../theme/institutional_theme.dart';
import '../models/task_model.dart';

class OverrideDialog extends StatefulWidget {
  final TaskItem task;
  final Function(String reason) onConfirmOverride;

  const OverrideDialog({
    super.key,
    required this.task,
    required this.onConfirmOverride,
  });

  @override
  State<OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<OverrideDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: InstitutionalTheme.bgOverride,
                      border: Border.all(color: InstitutionalTheme.statusOverride, width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.gavel,
                      color: InstitutionalTheme.statusOverride,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXECUTIVE OVERRIDE: FORCE COMPLETE',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: InstitutionalTheme.primaryNavy,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Institutional Protocol Override Authorization',
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: InstitutionalTheme.creamSurface,
                  border: Border.all(color: InstitutionalTheme.borderLedger),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUBJECT TASK: "${widget.task.title}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: InstitutionalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This task contains subtasks that do not meet standard completion criteria. By invoking Force Complete, you are superseding the completion rule under executive privilege.',
                      style: TextStyle(fontSize: 12, color: InstitutionalTheme.textBody),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MANDATORY JUSTIFICATION / REASON FOR OVERRIDE:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: InstitutionalTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Enter formal justification (e.g., Authorized by Board Resolution #42; remaining subtasks deferred to Q2)...',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 5) {
                    return 'A valid institutional reason (min. 5 characters) is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: InstitutionalTheme.statusEliminated),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action is permanently logged with your identity, timestamp, and justification into the institutional activity ledger and export reports.',
                        style: TextStyle(
                          fontSize: 11,
                          color: InstitutionalTheme.statusEliminated,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InstitutionalTheme.statusOverride,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onConfirmOverride(_reasonController.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('AUTHORIZE & COMPLETE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
