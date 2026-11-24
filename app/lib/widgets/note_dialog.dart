import 'package:flutter/material.dart';
import '../theme/institutional_theme.dart';

class NoteDialog extends StatefulWidget {
  final String title;
  final String initialNote;
  final Function(String newNote) onSave;

  const NoteDialog({
    super.key,
    required this.title,
    required this.initialNote,
    required this.onSave,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
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
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: InstitutionalTheme.creamSurface,
                    border: Border.all(color: InstitutionalTheme.goldAccent, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(Icons.description_outlined, color: InstitutionalTheme.goldDark, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INSTITUTIONAL DOCKET NOTE',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: InstitutionalTheme.primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 14),
            const Text(
              'SECRETARIAT OBSERVATIONS & PROGRESS NOTES:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: InstitutionalTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
              decoration: const InputDecoration(
                hintText: 'Record official remarks, progress updates, committee directives, or dependencies...',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onSave(_controller.text.trim());
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('SAVE NOTE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
