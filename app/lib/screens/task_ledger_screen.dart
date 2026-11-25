import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/task_model.dart';
import '../models/member_model.dart';
import '../widgets/status_chip.dart';
import '../widgets/note_dialog.dart';
import '../widgets/blocked_dialog.dart';
import '../widgets/override_dialog.dart';
import '../widgets/deadline_badge.dart';
import '../services/export_service.dart';

class TaskLedgerScreen extends StatefulWidget {
  final String filter; // 'ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'ELIMINATED'
  final String title;

  const TaskLedgerScreen({
    super.key,
    required this.filter,
    required this.title,
  });

  @override
  State<TaskLedgerScreen> createState() => _TaskLedgerScreenState();
}

class _TaskLedgerScreenState extends State<TaskLedgerScreen> {
  String _searchQuery = '';
  String? _selectedMemberFilter;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Select tasks according to widget filter
    List<TaskItem> baseTasks;
    switch (widget.filter) {
      case 'PENDING':
        baseTasks = appState.pendingTasks;
        break;
      case 'IN_PROGRESS':
        baseTasks = appState.inProgressTasks;
        break;
      case 'COMPLETED':
        baseTasks = appState.completedTasks;
        break;
      case 'ELIMINATED':
        baseTasks = appState.eliminatedTasks;
        break;
      case 'ALL':
      default:
        baseTasks = appState.getMainTasks();
        break;
    }

    final filteredTasks = baseTasks.where((task) {
      if (_selectedMemberFilter != null && !task.assignedMemberIds.contains(_selectedMemberFilter)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        final matchNote = task.note.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchNote) return false;
      }
      return true;
    }).toList();

    return Container(
      color: InstitutionalTheme.creamBackground,
      child: Column(
        children: [
          // Header / Filter Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: InstitutionalTheme.creamSurface,
              border: Border(bottom: BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Total Record Count: ${filteredTasks.length} Institutional Tasks',
                        style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                // Search Input
                SizedBox(
                  width: 200,
                  height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Filter records...',
                      prefixIcon: Icon(Icons.search, size: 16, color: InstitutionalTheme.textMuted),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                // Member Filter Dropdown
                DropdownButton<String?>(
                  value: _selectedMemberFilter,
                  hint: const Text('All Assignees', style: TextStyle(fontSize: 12)),
                  underline: const SizedBox(),
                  onChanged: (val) => setState(() => _selectedMemberFilter = val),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Assignees', style: TextStyle(fontSize: 12)),
                    ),
                    ...appState.members.map((m) => DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text(m.name, style: const TextStyle(fontSize: 12)),
                        )),
                  ],
                ),
                const SizedBox(width: 12),
                // MANDATED: ALL TASK LEDGER EXPORTABLE
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InstitutionalTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: () => _showExportLedgerDialog(context, filteredTasks, appState.members),
                  icon: const Icon(Icons.download, size: 16, color: InstitutionalTheme.goldAccent),
                  label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),

          // INSTITUTIONAL GOVERNANCE BANNER: Task modification restriction
          if (appState.activeMeeting == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF9C3),
                border: Border(bottom: BorderSide(color: Color(0xFFEAB308), width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_outlined, size: 16, color: Color(0xFF854D0E)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'VIEW-ONLY ARCHIVE: Tasks can only be added, updated, or have status changed while a meeting session is active.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF854D0E)),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: InstitutionalTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () => appState.setNavIndex(0),
                    icon: const Icon(Icons.meeting_room, size: 14),
                    label: const Text('CONVENE MEETING SESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                border: Border(bottom: BorderSide(color: Color(0xFF22C55E), width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF166534)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SESSION ACTIVE: "${appState.activeMeeting!.title}" • Docket modification & status updates enabled.',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),

          // Ledger Table / List
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text('No docket records found matching criteria.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final subtasks = appState.getSubtasks(task.id);
                      final assignedMembers = appState.getMembers(task.assignedMemberIds);
                      final originStr = DateFormat('yyyy-MM-dd').format(task.originMeetingDate);
                      final completedSubs = subtasks.where((s) => s.status == 'Completed').length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: InstitutionalTheme.borderLedger),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: ExpansionTile(
                          shape: const RoundedRectangleBorder(side: BorderSide.none),
                          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: StatusChip(
                            status: task.status,
                            isOverridden: task.isOverridden,
                            onTap: () => _showStatusChangeMenu(context, appState, task),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: InstitutionalTheme.primaryNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: InstitutionalTheme.creamSurface,
                                  border: Border.all(color: InstitutionalTheme.borderLedger),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'ORIGIN: $originStr',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstitutionalTheme.textMuted),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (assignedMembers.isNotEmpty)
                                      Text(
                                        'Assignees: ${assignedMembers.map((m) => m.name).join(", ")}',
                                        style: const TextStyle(fontSize: 11.5, color: InstitutionalTheme.textDark),
                                      )
                                    else
                                      const Text('Unassigned', style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
                                    const Spacer(),
                                    Text(
                                      'Subtasks: $completedSubs / ${subtasks.length} Done',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                                    ),
                                    const SizedBox(width: 14),
                                    IconButton(
                                      icon: Icon(
                                        task.note.isNotEmpty ? Icons.comment : Icons.comment_outlined,
                                        size: 18,
                                        color: task.note.isNotEmpty ? InstitutionalTheme.goldDark : Colors.grey,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => NoteDialog(
                                            title: task.title,
                                            initialNote: task.note,
                                            onSave: (note) => appState.updateTaskNote(task.id, note),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                DeadlineBadge(task: task),
                              ],
                            ),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: InstitutionalTheme.creamSurface,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description.isNotEmpty) ...[
                                    Text('Scope: ${task.description}', style: const TextStyle(fontSize: 12.5)),
                                    const SizedBox(height: 8),
                                  ],
                                  if (task.isOverridden && task.overrideReason != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: InstitutionalTheme.bgOverride,
                                        border: Border.all(color: InstitutionalTheme.statusOverride.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        'OVERRIDE AUDIT: ${task.overrideReason} (By ${task.overrideBy})',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: InstitutionalTheme.statusOverride),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  const Text(
                                    'SUBTASKS BREAKDOWN:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                                  ),
                                  const SizedBox(height: 6),
                                  if (subtasks.isEmpty)
                                    const Text('No subtasks attached to this docket entry.', style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic))
                                  else
                                    ...subtasks.map((sub) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.arrow_right, size: 18, color: InstitutionalTheme.primaryNavy),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(sub.title, style: const TextStyle(fontSize: 12.5)),
                                                    if (sub.deadline != null) ...[
                                                      const SizedBox(height: 2),
                                                      DeadlineBadge(task: sub, showInitiateDate: false),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              StatusChip(status: sub.status, isCompact: true),
                                            ],
                                          ),
                                        )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeMenu(BuildContext context, AppState appState, TaskItem task) {
    if (appState.activeMeeting == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: InstitutionalTheme.creamCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: InstitutionalTheme.primaryNavy, size: 22),
              SizedBox(width: 10),
              Text('MEETING SESSION REQUIRED', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: InstitutionalTheme.primaryNavy)),
            ],
          ),
          content: const Text(
            'Institutional governance mandates that task status, completion, and elimination can ONLY be recorded during an active meeting session.\n\nPlease convene a meeting session to modify this docket task.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                appState.setNavIndex(0); // Navigate to start/active meeting
              },
              icon: const Icon(Icons.meeting_room, size: 16),
              label: const Text('CONVENE SESSION NOW'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: InstitutionalTheme.creamCard,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPDATE DOCKET TASK STATE',
              style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...['Pending', 'In Progress', 'Completed', 'Eliminated'].map(
              (status) => ListTile(
                title: Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
                leading: Container(
                  width: 12,
                  height: 12,
                  color: InstitutionalTheme.getStatusColor(status),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final result = appState.updateTaskStatus(task.id, status);
                  if (!result.isAllowed) {
                    showDialog(
                      context: context,
                      builder: (bCtx) => BlockedDialog(
                        task: task,
                        ruleExplanation: result.message ?? 'Blocked',
                        openSubtasks: result.openSubtasks,
                        canOverride: result.canOverride,
                        onTriggerOverride: () {
                          showDialog(
                            context: context,
                            builder: (oCtx) => OverrideDialog(
                              task: task,
                              onConfirmOverride: (reason) {
                                appState.updateTaskStatus(
                                  task.id,
                                  'Completed',
                                  forceOverride: true,
                                  overrideReason: reason,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportLedgerDialog(BuildContext context, List<TaskItem> tasks, List<Member> members) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InstitutionalTheme.creamCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: InstitutionalTheme.creamSurface,
                border: Border.all(color: InstitutionalTheme.goldAccent),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.download, color: InstitutionalTheme.goldDark, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('EXPORT INSTITUTIONAL LEDGER', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: InstitutionalTheme.primaryNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select export format for the current ledger view (${tasks.length} tasks matching current filters):',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
              leading: const Icon(Icons.table_chart, color: Color(0xFF16A34A)),
              title: const Text('Export to Microsoft Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Formatted multi-column spreadsheet with task metadata, assignees & status', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  final path = await ExportService.exportTaskLedgerToExcel(
                    tasks: tasks,
                    members: members,
                    filterName: widget.title,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Master Task Ledger successfully exported to Excel!\nLocation: $path'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Excel export error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626)),
              title: const Text('Export to Formal PDF Document (.pdf)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Print-ready formal institutional register with headers and seals', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await ExportService.exportTaskLedgerToPdf(
                    tasks: tasks,
                    members: members,
                    filterName: widget.title,
                    settings: context.read<AppState>().settings,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF export error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL')),
        ],
      ),
    );
  }
}
