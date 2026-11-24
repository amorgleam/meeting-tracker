import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/task_model.dart';
import '../widgets/status_chip.dart';
import '../widgets/blocked_dialog.dart';
import '../widgets/override_dialog.dart';
import '../widgets/note_dialog.dart';
import '../widgets/deadline_picker_field.dart';
import '../widgets/deadline_badge.dart';

class ActiveMeetingScreen extends StatefulWidget {
  const ActiveMeetingScreen({super.key});

  @override
  State<ActiveMeetingScreen> createState() => _ActiveMeetingScreenState();
}

class _ActiveMeetingScreenState extends State<ActiveMeetingScreen> {
  final Set<String> _expandedTaskIds = {};
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, IN_PROGRESS, COMPLETED, ELIMINATED

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meeting = appState.activeMeeting;

    if (meeting == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: InstitutionalTheme.creamCard,
            border: Border.all(color: InstitutionalTheme.borderLedger),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.meeting_room_outlined, size: 48, color: InstitutionalTheme.primaryNavy),
              const SizedBox(height: 16),
              const Text(
                'NO ACTIVE MEETING IN SESSION',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: InstitutionalTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select a date to convene an institutional session.',
                textAlign: TextAlign.center,
                style: TextStyle(color: InstitutionalTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appState.setNavIndex(0),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('CONVENE SESSION NOW'),
              ),
            ],
          ),
        ),
      );
    }

    // Meeting tasks: New tasks + Carried forward tasks
    final allMeetingTasks = appState.getAllMeetingTasks();
    final newTasks = appState.getNewTasksForMeeting();
    final carriedTasks = appState.getCarriedForwardTasks();

    // Filtered
    final filteredTasks = allMeetingTasks.where((task) {
      if (_statusFilter != 'ALL' && task.status.toUpperCase().replaceAll(' ', '_') != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchNote = task.note.toLowerCase().contains(q);
        if (!matchTitle && !matchNote) return false;
      }
      return true;
    }).toList();

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Container(
      color: InstitutionalTheme.creamBackground,
      child: Column(
        children: [
          // 1. Session Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: InstitutionalTheme.creamSurface,
              border: Border(
                bottom: BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 650;
                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: InstitutionalTheme.statusCompleted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'ACTIVE SESSION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dateFormat.format(meeting.meetingDate),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: InstitutionalTheme.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meeting.title.isNotEmpty ? meeting.title : 'Institutional Steering Committee Meeting',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: InstitutionalTheme.textDark,
                      ),
                    ),
                  ],
                );

                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMetricsBadge('NEW', newTasks.length, InstitutionalTheme.primaryNavy),
                    const SizedBox(width: 8),
                    _buildMetricsBadge('CARRIED', carriedTasks.length, InstitutionalTheme.goldDark),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: InstitutionalTheme.statusEliminated,
                        side: const BorderSide(color: InstitutionalTheme.statusEliminated),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _confirmAdjourn(context, appState),
                      icon: const Icon(Icons.stop_circle_outlined, size: 16),
                      label: const Text('ADJOURN SESSION'),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      info,
                      const SizedBox(height: 12),
                      SingleChildScrollView(scrollDirection: Axis.horizontal, child: actions),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: info),
                    actions,
                  ],
                );
              },
            ),
          ),

          // 2. Control Bar (Add Task & Status Filters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: InstitutionalTheme.borderLedger, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddTaskDialog(context, appState),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('ADD MAIN TASK'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status Filter Segmented Buttons
                  _filterButton('ALL', 'All (${allMeetingTasks.length})'),
                  _filterButton('PENDING', 'Pending (${allMeetingTasks.where((t) => t.status == "Pending").length})'),
                  _filterButton('IN_PROGRESS', 'In Progress (${allMeetingTasks.where((t) => t.status == "In Progress").length})'),
                  _filterButton('COMPLETED', 'Completed (${allMeetingTasks.where((t) => t.status == "Completed").length})'),
                  _filterButton('ELIMINATED', 'Eliminated (${allMeetingTasks.where((t) => t.status == "Eliminated").length})'),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 220,
                    height: 36,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search docket...',
                        prefixIcon: Icon(Icons.search, size: 16, color: InstitutionalTheme.textMuted),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Main Tasks Register / Ledger
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks matching criteria in this docket session.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final isCarried = task.originMeetingDate.isBefore(
                        DateTime(meeting.meetingDate.year, meeting.meetingDate.month, meeting.meetingDate.day),
                      );
                      final isExpanded = _expandedTaskIds.contains(task.id);
                      final subtasks = appState.getSubtasks(task.id);

                      return _buildMainTaskCard(
                        context,
                        appState,
                        task: task,
                        subtasks: subtasks,
                        isCarried: isCarried,
                        isExpanded: isExpanded,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String filterKey, String label) {
    final isSelected = _statusFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _statusFilter = filterKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? InstitutionalTheme.primaryNavy : Colors.transparent,
            border: Border.all(
              color: isSelected ? InstitutionalTheme.primaryNavy : InstitutionalTheme.borderLedger,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : InstitutionalTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTaskCard(
    BuildContext context,
    AppState appState, {
    required TaskItem task,
    required List<TaskItem> subtasks,
    required bool isCarried,
    required bool isExpanded,
  }) {
    final assignedMembers = appState.getMembers(task.assignedMemberIds);
    final originDateStr = DateFormat('yyyy-MM-dd').format(task.originMeetingDate);

    final isWideScreen = MediaQuery.of(context).size.width >= 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: InstitutionalTheme.creamCard,
        border: Border.all(
          color: isCarried ? InstitutionalTheme.goldAccent.withOpacity(0.7) : InstitutionalTheme.borderLedger,
          width: isCarried ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Carried Badge
          if (isCarried)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF4E4),
                border: Border(bottom: BorderSide(color: Color(0xFFE5D5A4))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_toggle_off, size: 14, color: InstitutionalTheme.goldDark),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'CARRIED FORWARD FROM SESSION $originDateStr (UNRESOLVED PAST DOCKET)',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: InstitutionalTheme.goldDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expand toggle
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedTaskIds.remove(task.id);
                            } else {
                              _expandedTaskIds.add(task.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),

                      // Main Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: InstitutionalTheme.primaryNavy,
                              ),
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                style: const TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                              ),
                            ],
                            const SizedBox(height: 8),

                            // Assigned Members & Subtasks count
                            Row(
                              children: [
                                const Icon(Icons.people_alt_outlined, size: 14, color: InstitutionalTheme.textMuted),
                                const SizedBox(width: 6),
                                if (assignedMembers.isEmpty)
                                  const Expanded(
                                    child: Text(
                                      'Unassigned',
                                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: InstitutionalTheme.textMuted),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: assignedMembers.map((m) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: InstitutionalTheme.creamSurface,
                                            border: Border.all(color: InstitutionalTheme.borderLedger),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            m.name,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: InstitutionalTheme.textDark),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x111F3A5F),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    '${subtasks.length} Subtasks',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DeadlineBadge(
                              task: task,
                              onTap: () => _showDeadlineEditDialog(context, appState, task),
                            ),

                            if (task.isOverridden && task.overrideReason != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: InstitutionalTheme.bgOverride,
                                  border: Border.all(color: InstitutionalTheme.statusOverride.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'COMPLETED BY OVERRIDE: ${task.overrideReason} (Auth: ${task.overrideBy ?? "Admin"})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: InstitutionalTheme.statusOverride,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Note Button
                      IconButton(
                        tooltip: 'View or edit docket notes',
                        icon: Badge(
                          isLabelVisible: task.note.isNotEmpty,
                          label: const Text('!', style: TextStyle(fontSize: 9)),
                          backgroundColor: InstitutionalTheme.goldAccent,
                          child: Icon(
                            task.note.isNotEmpty ? Icons.comment : Icons.comment_outlined,
                            color: task.note.isNotEmpty ? InstitutionalTheme.goldDark : InstitutionalTheme.textMuted,
                            size: 20,
                          ),
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

                      const SizedBox(width: 8),

                      // Status Dropdown Selector with rule check
                      _buildStatusDropdown(context, appState, task),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mobile Top Row: Expand + Title + Status Chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedTaskIds.remove(task.id);
                                } else {
                                  _expandedTaskIds.add(task.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                color: InstitutionalTheme.primaryNavy,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
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
                          _buildStatusDropdown(context, appState, task, isCompact: true),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description,
                          style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textBody),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Assigned Members
                      if (assignedMembers.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: assignedMembers.map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: InstitutionalTheme.creamSurface,
                                border: Border.all(color: InstitutionalTheme.borderLedger),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                m.name,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: InstitutionalTheme.textDark),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      DeadlineBadge(
                        task: task,
                        onTap: () => _showDeadlineEditDialog(context, appState, task),
                      ),
                      const SizedBox(height: 8),
                      // Mobile Footer Row: Subtasks count + Note Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x111F3A5F),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '${subtasks.length} Subtasks',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                            ),
                          ),
                          IconButton(
                            icon: Badge(
                              isLabelVisible: task.note.isNotEmpty,
                              label: const Text('!', style: TextStyle(fontSize: 9)),
                              backgroundColor: InstitutionalTheme.goldAccent,
                              child: Icon(
                                task.note.isNotEmpty ? Icons.comment : Icons.comment_outlined,
                                color: task.note.isNotEmpty ? InstitutionalTheme.goldDark : InstitutionalTheme.textMuted,
                                size: 18,
                              ),
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
                      if (task.isOverridden && task.overrideReason != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: InstitutionalTheme.bgOverride,
                            border: Border.all(color: InstitutionalTheme.statusOverride.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'COMPLETED BY OVERRIDE: ${task.overrideReason}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: InstitutionalTheme.statusOverride,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // 4. Expanded Subtasks Section
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              color: InstitutionalTheme.creamSurface.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SUBTASKS REGISTER:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddSubtaskDialog(context, appState, task.id),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('ADD SUBTASK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (subtasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No subtasks recorded. Click "Add Subtask" to track itemized components.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: InstitutionalTheme.textMuted),
                      ),
                    )
                  else
                    ...subtasks.map((sub) => _buildSubtaskRow(context, appState, sub)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtaskRow(BuildContext context, AppState appState, TaskItem subtask) {
    final assignedMembers = appState.getMembers(subtask.assignedMemberIds);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: InstitutionalTheme.borderLedger),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16, color: InstitutionalTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: InstitutionalTheme.textDark),
                ),
                if (assignedMembers.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    assignedMembers.map((m) => m.name).join(', '),
                    style: const TextStyle(fontSize: 11, color: InstitutionalTheme.textMuted),
                  ),
                ],
                const SizedBox(height: 4),
                DeadlineBadge(
                  task: subtask,
                  showInitiateDate: false,
                  onTap: () => _showDeadlineEditDialog(context, appState, subtask),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              subtask.note.isNotEmpty ? Icons.comment : Icons.comment_outlined,
              size: 16,
              color: subtask.note.isNotEmpty ? InstitutionalTheme.goldDark : InstitutionalTheme.textMuted,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => NoteDialog(
                  title: subtask.title,
                  initialNote: subtask.note,
                  onSave: (note) => appState.updateTaskNote(subtask.id, note),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildStatusDropdown(context, appState, subtask, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, AppState appState, TaskItem task, {bool isCompact = false}) {
    return PopupMenuButton<String>(
      tooltip: 'Change State',
      child: StatusChip(
        status: task.status,
        isOverridden: task.isOverridden,
        isCompact: isCompact,
      ),
      onSelected: (newStatus) {
        _handleStatusChange(context, appState, task, newStatus);
      },
      itemBuilder: (context) => [
        _buildPopupItem('Pending', InstitutionalTheme.statusPending),
        _buildPopupItem('In Progress', InstitutionalTheme.statusInProgress),
        _buildPopupItem('Completed', InstitutionalTheme.statusCompleted),
        _buildPopupItem('Eliminated', InstitutionalTheme.statusEliminated),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String status, Color color) {
    return PopupMenuItem<String>(
      value: status,
      child: Row(
        children: [
          Container(width: 8, height: 8, color: color),
          const SizedBox(width: 10),
          Text(status, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _handleStatusChange(BuildContext context, AppState appState, TaskItem task, String newStatus) {
    final result = appState.updateTaskStatus(task.id, newStatus);

    if (!result.isAllowed) {
      // Rule blocked! Show BlockedDialog
      showDialog(
        context: context,
        builder: (ctx) => BlockedDialog(
          task: task,
          ruleExplanation: result.message ?? 'Task completion protocol blocked.',
          openSubtasks: result.openSubtasks,
          canOverride: result.canOverride,
          onTriggerOverride: () {
            // Trigger Override Dialog
            showDialog(
              context: context,
              builder: (ctx) => OverrideDialog(
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
  }

  void _showDeadlineEditDialog(BuildContext context, AppState appState, TaskItem task) {
    DateTime? newDeadline = task.deadline;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: InstitutionalTheme.creamCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
          title: Row(
            children: [
              const Icon(Icons.alarm, color: InstitutionalTheme.primaryNavy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ADJUST DOCKET DEADLINE: ${task.title}',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: InstitutionalTheme.primaryNavy),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: DeadlinePickerField(
              initiateDate: task.initiateDate,
              initialDeadline: newDeadline,
              onDeadlineChanged: (d) => setDialogState(() => newDeadline = d),
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                appState.updateTaskDeadline(task.id, newDeadline);
                Navigator.of(ctx).pop();
              },
              child: const Text('SAVE DEADLINE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final noteController = TextEditingController();
    final Set<String> assignedIds = {};
    DateTime? selectedDeadline;
    final initiateDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: InstitutionalTheme.creamCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECORD NEW MAIN DOCKET TASK',
                    style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title *', hintText: 'e.g. Implement Barcode Filing System'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description / Scope', hintText: 'Formal mandate or action specifications'),
                  ),
                  const SizedBox(height: 14),
                  DeadlinePickerField(
                    initiateDate: initiateDate,
                    initialDeadline: selectedDeadline,
                    onDeadlineChanged: (d) => setDialogState(() => selectedDeadline = d),
                  ),
                  const SizedBox(height: 14),
                  const Text('ASSIGN TO MEMBERS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: appState.members.where((m) => m.isActive).map((m) {
                      final isAssigned = assignedIds.contains(m.id);
                      return ChoiceChip(
                        label: Text(m.name),
                        selected: isAssigned,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              assignedIds.add(m.id);
                            } else {
                              assignedIds.remove(m.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Initial Secretariat Note (Optional)', hintText: 'Initial observation or directive'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            appState.addMainTask(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              assignedMemberIds: assignedIds.toList(),
                              note: noteController.text.trim(),
                              initiateDate: initiateDate,
                              deadline: selectedDeadline,
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('RECORD TASK'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSubtaskDialog(BuildContext context, AppState appState, String parentTaskId) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final Set<String> assignedIds = {};
    DateTime? selectedDeadline;
    final initiateDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: InstitutionalTheme.creamCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
          child: Container(
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECORD SUBTASK COMPONENT',
                    style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Subtask Action Title *', hintText: 'e.g. Conduct laser scanner hardware test'),
                  ),
                  const SizedBox(height: 14),
                  DeadlinePickerField(
                    initiateDate: initiateDate,
                    initialDeadline: selectedDeadline,
                    onDeadlineChanged: (d) => setDialogState(() => selectedDeadline = d),
                  ),
                  const SizedBox(height: 14),
                  const Text('ASSIGN SUBTASK TO:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: appState.members.where((m) => m.isActive).map((m) {
                      final isAssigned = assignedIds.contains(m.id);
                      return ChoiceChip(
                        label: Text(m.name),
                        selected: isAssigned,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              assignedIds.add(m.id);
                            } else {
                              assignedIds.remove(m.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Subtask Note', hintText: 'Detailed requirements or deadline'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            appState.addSubtask(
                              parentTaskId: parentTaskId,
                              title: titleController.text.trim(),
                              assignedMemberIds: assignedIds.toList(),
                              note: noteController.text.trim(),
                              initiateDate: initiateDate,
                              deadline: selectedDeadline,
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('ADD SUBTASK'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmAdjourn(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InstitutionalTheme.creamCard,
        title: const Text('ADJOURN FORMAL SESSION?', style: TextStyle(fontFamily: 'serif', color: InstitutionalTheme.primaryNavy)),
        content: const Text(
          'Adjourning this session will seal the meeting proceedings and archive unresolved tasks for carry-forward into future meetings.',
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CONTINUE SESSION')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: InstitutionalTheme.primaryNavy),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.endMeeting();
            },
            child: const Text('SEAL & ADJOURN'),
          ),
        ],
      ),
    );
  }
}
