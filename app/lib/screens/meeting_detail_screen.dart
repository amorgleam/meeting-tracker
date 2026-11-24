import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/meeting_model.dart';
import '../models/task_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';
import '../widgets/status_chip.dart';
import '../services/export_service.dart';

class MeetingDetailScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meeting = widget.meeting;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(meeting.meetingDate);

    // Three Sections mandated:
    // a) New tasks added in this meeting
    final newTasks = appState.getNewTasksForMeeting(targetMeeting: meeting);
    // b) Past tasks carried forward (Pending and In Progress only)
    final carriedTasks = appState.getCarriedForwardTasks(targetMeeting: meeting);
    // c) "Work done in this meeting": state change log
    final workDoneLogs = appState.getWorkDoneForMeeting(meeting.id);

    return Scaffold(
      backgroundColor: InstitutionalTheme.creamBackground,
      appBar: AppBar(
        title: Text(meeting.title.isNotEmpty ? meeting.title.toUpperCase() : 'MEETING PROCEEDINGS'),
        actions: [
          IconButton(
            tooltip: 'Export Meeting Proceedings (Excel/PDF)',
            icon: const Icon(Icons.download, color: InstitutionalTheme.goldAccent),
            onPressed: () => _showExportMeetingDialog(
              context: context,
              meeting: meeting,
              newTasks: newTasks,
              carriedTasks: carriedTasks,
              workDoneLogs: workDoneLogs,
              members: appState.members,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Institutional Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: InstitutionalTheme.primaryNavy,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              dateStr.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'STATUS: ${meeting.status.toUpperCase()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meeting.title.isNotEmpty ? meeting.title : 'Official Institutional Session',
                        style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                      ),
                      if (meeting.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(meeting.notes, style: const TextStyle(fontSize: 13, color: InstitutionalTheme.textBody)),
                      ],
                    ],
                  ),
                ),
                // Attendees count
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: InstitutionalTheme.borderLedger),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${meeting.attendeeMemberIds.length}',
                        style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                      ),
                      const Text('Attendees', style: TextStyle(fontSize: 11, color: InstitutionalTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MANDATED THREE TABS / SECTIONS
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: InstitutionalTheme.primaryNavy,
              unselectedLabelColor: InstitutionalTheme.textMuted,
              indicatorColor: InstitutionalTheme.goldAccent,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'SECTION A: NEW TASKS (${newTasks.length})'),
                Tab(text: 'SECTION B: CARRIED FORWARD (${carriedTasks.length})'),
                Tab(text: 'SECTION C: WORK DONE IN MEETING (${workDoneLogs.length})'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // SECTION A: New tasks added in this meeting
                _buildTasksList(context, appState, newTasks, 'No new tasks originated in this meeting.'),
                // SECTION B: Past tasks carried forward
                _buildTasksList(context, appState, carriedTasks, 'No carried-forward tasks pending from past meetings.', isCarried: true),
                // SECTION C: "Work done in this meeting" Activity Log
                _buildWorkDoneLogList(context, appState, workDoneLogs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, AppState appState, List<TaskItem> tasks, String emptyMsg, {bool isCarried = false}) {
    if (tasks.isEmpty) {
      return Center(child: Text(emptyMsg, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final subtasks = appState.getSubtasks(task.id);
        final members = appState.getMembers(task.assignedMemberIds);
        final originStr = DateFormat('yyyy-MM-dd').format(task.originMeetingDate);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: InstitutionalTheme.borderLedger),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                  ),
                ),
                StatusChip(status: task.status, isOverridden: task.isOverridden),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (isCarried)
                  Text(
                    'Carried from session date: $originStr',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.goldDark),
                  ),
                if (members.isNotEmpty)
                  Text(
                    'Assignees: ${members.map((m) => m.name).join(", ")}',
                    style: const TextStyle(fontSize: 11.5, color: InstitutionalTheme.textDark),
                  ),
                if (task.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Docket Note: ${task.note}', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: InstitutionalTheme.textMuted)),
                  ),
              ],
            ),
            children: [
              if (subtasks.isNotEmpty)
                Container(
                  color: InstitutionalTheme.creamSurface,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SUBTASKS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy)),
                      const SizedBox(height: 6),
                      ...subtasks.map((sub) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_right, size: 16),
                                Expanded(child: Text(sub.title, style: const TextStyle(fontSize: 12))),
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
    );
  }

  Widget _buildWorkDoneLogList(BuildContext context, AppState appState, List<ActivityLog> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('No state modifications or activity logged during this session.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: InstitutionalTheme.borderLedger),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: InstitutionalTheme.creamSurface,
                  border: Border.all(color: InstitutionalTheme.borderLedger),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.taskTitle,
                      style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 13, color: InstitutionalTheme.primaryNavy),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusChip(status: log.oldState, isCompact: true),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward, size: 14, color: InstitutionalTheme.textMuted),
                        ),
                        StatusChip(status: log.newState, isCompact: true),
                        const SizedBox(width: 10),
                        Text('Recorded by: ${log.userName}', style: const TextStyle(fontSize: 11, color: InstitutionalTheme.textMuted)),
                      ],
                    ),
                    if (log.isOverride) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: InstitutionalTheme.bgOverride,
                        child: Text(
                          'COMPLETED BY OVERRIDE: ${log.overrideReason ?? ""}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.statusOverride),
                        ),
                      ),
                    ],
                    if (log.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Remarks: ${log.note}', style: const TextStyle(fontSize: 11.5, color: InstitutionalTheme.textBody)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportMeetingDialog({
    required BuildContext context,
    required Meeting meeting,
    required List<TaskItem> newTasks,
    required List<TaskItem> carriedTasks,
    required List<ActivityLog> workDoneLogs,
    required List<Member> members,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InstitutionalTheme.creamBackground,
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
            const Text('EXPORT MEETING PROCEEDINGS', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: InstitutionalTheme.primaryNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select export format. Proceedings include Section A (New Tasks), Section B (Carried Forward), and Section C (Work Done / State Changes):',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
              leading: const Icon(Icons.table_chart, color: Color(0xFF16A34A)),
              title: const Text('Export to Microsoft Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Multi-tab workbook containing all 3 mandated sections', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  final path = await ExportService.exportMeetingToExcel(
                    meeting: meeting,
                    newTasks: newTasks,
                    carriedTasks: carriedTasks,
                    workDoneLogs: workDoneLogs,
                    members: members,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Meeting proceedings successfully exported to Excel!\nFile: $path'),
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
              subtitle: const Text('Print-ready formal institutional proceedings with headers and seals', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await ExportService.exportMeetingToPdf(
                    meeting: meeting,
                    newTasks: newTasks,
                    carriedTasks: carriedTasks,
                    workDoneLogs: workDoneLogs,
                    members: members,
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
