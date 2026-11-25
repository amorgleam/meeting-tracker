import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';
import '../models/app_settings_model.dart';
import '../rules/completion_rules.dart';
import '../database/local_database.dart';
import '../sync/sync_service.dart';

class AppState extends ChangeNotifier {
  static const _uuid = Uuid();

  Meeting? _activeMeeting;
  final List<Meeting> _meetings = [];
  final List<TaskItem> _tasks = [];
  final List<Member> _members = [];
  final List<ActivityLog> _activityLogs = [];
  AppSettings _settings = AppSettings();
  int _selectedNavIndex = 0;
  String _taskFilter = 'ALL'; // 'ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'ELIMINATED'

  // Getters
  Meeting? get activeMeeting => _activeMeeting;
  List<Meeting> get meetings => List.unmodifiable(_meetings);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<Member> get members => List.unmodifiable(_members);
  List<ActivityLog> get activityLogs => List.unmodifiable(_activityLogs);
  AppSettings get settings => _settings;
  int get selectedNavIndex => _selectedNavIndex;
  String get taskFilter => _taskFilter;

  AppState() {
    _initSeedData();
    initDatabase();
  }

  Future<void> initDatabase() async {
    try {
      await LocalDatabase.instance.init();
      final dbMembers = LocalDatabase.instance.getMembers();
      if (dbMembers.isNotEmpty) {
        _members.clear();
        _members.addAll(dbMembers);
        _meetings.clear();
        _meetings.addAll(LocalDatabase.instance.getMeetings());
        _tasks.clear();
        _tasks.addAll(LocalDatabase.instance.getTasks());
        _activityLogs.clear();
        _activityLogs.addAll(LocalDatabase.instance.getActivityLogs());
        try {
          _activeMeeting = _meetings.firstWhere((m) => m.status == 'In Progress');
        } catch (_) {
          _activeMeeting = null;
        }
      } else {
        for (final m in _members) {
          LocalDatabase.instance.insertMember(m, enqueueOutbox: false);
        }
        for (final meet in _meetings) {
          LocalDatabase.instance.insertMeeting(meet, enqueueOutbox: false);
        }
        for (final t in _tasks) {
          LocalDatabase.instance.insertTask(t, enqueueOutbox: false);
        }
        for (final a in _activityLogs) {
          LocalDatabase.instance.insertActivityLog(a, enqueueOutbox: false);
        }
      }
      SyncService.instance.configure(
        serverBaseUrl: _settings.serverUrl,
        deviceId: _settings.deviceId,
        onDataChangedCallback: _reloadFromDatabase,
      );
      SyncService.instance.startPeriodicSync();
      notifyListeners();
    } catch (e) {
      debugPrint('LocalDatabase init fallback: $e');
    }
  }

  void _reloadFromDatabase() {
    _members.clear();
    _members.addAll(LocalDatabase.instance.getMembers());
    _meetings.clear();
    _meetings.addAll(LocalDatabase.instance.getMeetings());
    _tasks.clear();
    _tasks.addAll(LocalDatabase.instance.getTasks());
    _activityLogs.clear();
    _activityLogs.addAll(LocalDatabase.instance.getActivityLogs());
    try {
      _activeMeeting = _meetings.firstWhere((m) => m.status == 'In Progress');
    } catch (_) {
      _activeMeeting = null;
    }
    notifyListeners();
  }

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  void setTaskFilter(String filter) {
    _taskFilter = filter;
    notifyListeners();
  }

  // Settings
  void updateCompletionRule(CompletionRuleMode mode) {
    _settings = _settings.copyWith(completionRule: mode);
    notifyListeners();
  }

  void updateUserRole(String role) {
    _settings = _settings.copyWith(userRole: role);
    notifyListeners();
  }

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    SyncService.instance.configure(
      serverBaseUrl: _settings.serverUrl,
      deviceId: _settings.deviceId,
      onDataChangedCallback: _reloadFromDatabase,
    );
    SyncService.instance.sync();
    notifyListeners();
  }

  // --- Meeting Operations ---
  Meeting startMeeting(DateTime date, {String? title, List<String>? attendeeIds}) {
    final meeting = Meeting(
      id: _uuid.v4(),
      meetingDate: date,
      title: (title != null && title.trim().isNotEmpty) ? title.trim() : 'Executive Session - ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      attendeeMemberIds: attendeeIds ?? _members.where((m) => m.isActive).map((m) => m.id).toList(),
      status: 'In Progress',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deviceId: _settings.deviceId,
    );
    _activeMeeting = meeting;
    _meetings.insert(0, meeting);
    _selectedNavIndex = 0; // Go to Active Meeting
    try {
      LocalDatabase.instance.insertMeeting(meeting);
    } catch (_) {}
    notifyListeners();
    return meeting;
  }

  void endMeeting() {
    if (_activeMeeting != null) {
      final idx = _meetings.indexWhere((m) => m.id == _activeMeeting!.id);
      if (idx != -1) {
        _meetings[idx] = _activeMeeting!.copyWith(
          status: 'Adjourned',
          updatedAt: DateTime.now(),
        );
        try {
          LocalDatabase.instance.insertMeeting(_meetings[idx]);
        } catch (_) {}
      }
      _activeMeeting = null;
      notifyListeners();
    }
  }

  // --- Task Operations ---
  TaskItem? addMainTask({
    required String title,
    String? description,
    List<String>? assignedMemberIds,
    String? note,
    DateTime? originDate,
    DateTime? initiateDate,
    DateTime? deadline,
  }) {
    if (_activeMeeting == null) {
      return null; // Restricted to active meetings only
    }

    final entryTime = initiateDate ?? DateTime.now();
    final meetingId = _activeMeeting!.id;
    final meetingDate = originDate ?? _activeMeeting!.meetingDate;

    final task = TaskItem(
      id: _uuid.v4(),
      meetingId: meetingId,
      parentTaskId: null,
      title: title.trim(),
      description: description?.trim() ?? '',
      status: 'Pending',
      assignedMemberIds: assignedMemberIds ?? [],
      note: note?.trim() ?? '',
      originMeetingDate: meetingDate,
      deadline: deadline,
      orderIndex: _tasks.where((t) => t.isMainTask).length,
      createdAt: entryTime,
      updatedAt: DateTime.now(),
      deviceId: _settings.deviceId,
    );

    _tasks.add(task);
    try {
      LocalDatabase.instance.insertTask(task);
    } catch (_) {}

    // Record in activity log
    _logActivity(
      taskId: task.id,
      taskTitle: task.title,
      oldState: 'NEW',
      newState: 'Pending',
      note: deadline != null
          ? 'Task entered into docket with deadline ${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}'
          : 'Task formally recorded into docket during session',
      meetingId: meetingId,
    );

    notifyListeners();
    return task;
  }

  TaskItem? addSubtask({
    required String parentTaskId,
    required String title,
    String? description,
    List<String>? assignedMemberIds,
    String? note,
    DateTime? initiateDate,
    DateTime? deadline,
  }) {
    if (_activeMeeting == null) {
      return null; // Restricted to active meetings only
    }

    final entryTime = initiateDate ?? DateTime.now();
    final parent = _tasks.firstWhere((t) => t.id == parentTaskId);
    final meetingId = _activeMeeting!.id;

    final subtask = TaskItem(
      id: _uuid.v4(),
      meetingId: meetingId,
      parentTaskId: parentTaskId,
      title: title.trim(),
      description: description?.trim() ?? '',
      status: 'Pending',
      assignedMemberIds: assignedMemberIds ?? parent.assignedMemberIds,
      note: note?.trim() ?? '',
      originMeetingDate: parent.originMeetingDate,
      deadline: deadline,
      orderIndex: _tasks.where((t) => t.parentTaskId == parentTaskId).length,
      createdAt: entryTime,
      updatedAt: DateTime.now(),
      deviceId: _settings.deviceId,
    );

    _tasks.add(subtask);
    try {
      LocalDatabase.instance.insertTask(subtask);
    } catch (_) {}

    _logActivity(
      taskId: subtask.id,
      taskTitle: '${parent.title} > ${subtask.title}',
      oldState: 'NEW',
      newState: 'Pending',
      note: deadline != null
          ? 'Subtask entered with deadline ${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}'
          : 'Subtask initiated during session',
      meetingId: meetingId,
    );

    notifyListeners();
    return subtask;
  }

  /// Changes task state with completion rule validation.
  /// Enforces that an active meeting MUST be running.
  CompletionRuleValidationResult updateTaskStatus(
    String taskId,
    String newStatus, {
    bool forceOverride = false,
    String? overrideReason,
    bool allowWithoutActiveMeeting = false,
  }) {
    // Institutional Mandate: Tasks can only be changed or updated if a meeting is active
    if (_activeMeeting == null && !allowWithoutActiveMeeting) {
      return const CompletionRuleValidationResult(
        isAllowed: false,
        message: 'DOCKET MODIFICATION BLOCKED: Institutional governance mandates that task status and docket items can ONLY be modified while a formal meeting session is in progress. Please convene a meeting first.',
        canOverride: false,
      );
    }

    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) {
      return const CompletionRuleValidationResult(isAllowed: false, message: 'Task not found');
    }

    final task = _tasks[taskIndex];
    if (task.status == newStatus) {
      return const CompletionRuleValidationResult(isAllowed: true);
    }

    // If changing a Main Task to "Completed", enforce completion rule!
    if (task.isMainTask && newStatus == 'Completed') {
      final subtasks = getSubtasks(taskId);
      final validation = CompletionRules.validateCompletion(
        mainTask: task,
        subtasks: subtasks,
        mode: _settings.completionRule,
        userRole: _settings.userRole,
      );

      if (!validation.isAllowed) {
        if (!forceOverride) {
          return validation; // Blocked!
        }

        // Force Override requested
        if (!CompletionRules.canUserOverride(_settings.userRole)) {
          return const CompletionRuleValidationResult(
            isAllowed: false,
            message: 'Unauthorized: Only Admin or Secretary roles may execute an override.',
            canOverride: false,
          );
        }

        if (overrideReason == null || overrideReason.trim().isEmpty) {
          return const CompletionRuleValidationResult(
            isAllowed: false,
            message: 'A formal reason is required for executive override.',
            canOverride: true,
          );
        }

        // Apply override completion
        final updatedTask = task.copyWith(
          status: 'Completed',
          isOverridden: true,
          overrideReason: overrideReason.trim(),
          overrideBy: _settings.currentUserName,
          overrideAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: task.version + 1,
        );

        _tasks[taskIndex] = updatedTask;
        try {
          LocalDatabase.instance.insertTask(updatedTask);
        } catch (_) {}

        _logActivity(
          taskId: task.id,
          taskTitle: task.title,
          oldState: task.status,
          newState: 'Completed',
          note: 'Completed by override: $overrideReason',
          isOverride: true,
          overrideReason: overrideReason.trim(),
          meetingId: _activeMeeting?.id,
        );

        notifyListeners();
        return const CompletionRuleValidationResult(isAllowed: true);
      }
    }

    // Normal state transition
    final updatedTask = task.copyWith(
      status: newStatus,
      isOverridden: false,
      updatedAt: DateTime.now(),
      version: task.version + 1,
    );

    _tasks[taskIndex] = updatedTask;
    try {
      LocalDatabase.instance.insertTask(updatedTask);
    } catch (_) {}

    _logActivity(
      taskId: task.id,
      taskTitle: task.title,
      oldState: task.status,
      newState: newStatus,
      note: 'State updated to $newStatus',
      meetingId: _activeMeeting?.id,
    );

    notifyListeners();
    return const CompletionRuleValidationResult(isAllowed: true);
  }

  void updateTaskNote(String taskId, String note) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        note: note.trim(),
        updatedAt: DateTime.now(),
        version: _tasks[idx].version + 1,
      );
      try {
        LocalDatabase.instance.insertTask(_tasks[idx]);
      } catch (_) {}
      _logActivity(
        taskId: taskId,
        taskTitle: _tasks[idx].title,
        oldState: _tasks[idx].status,
        newState: _tasks[idx].status,
        note: 'Note updated: $note',
        meetingId: _activeMeeting?.id,
      );
      notifyListeners();
    }
  }

  void updateTaskDeadline(String taskId, DateTime? newDeadline) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks[idx];
      _tasks[idx] = task.copyWith(
        deadline: newDeadline,
        clearDeadline: newDeadline == null,
        updatedAt: DateTime.now(),
        version: task.version + 1,
      );
      try {
        LocalDatabase.instance.insertTask(_tasks[idx]);
      } catch (_) {}

      final deadlineStr = newDeadline != null
          ? '${newDeadline.year}-${newDeadline.month.toString().padLeft(2, '0')}-${newDeadline.day.toString().padLeft(2, '0')}'
          : 'Cleared';

      _logActivity(
        taskId: taskId,
        taskTitle: task.title,
        oldState: task.status,
        newState: task.status,
        note: 'Deadline adjusted to: $deadlineStr',
        meetingId: _activeMeeting?.id,
      );
      notifyListeners();
    }
  }

  // --- Member Operations ---
  Member addMember({
    required String name,
    String? email,
    String? designation,
  }) {
    final now = DateTime.now();
    final member = Member(
      id: _uuid.v4(),
      name: name.trim(),
      email: email?.trim() ?? '',
      designation: designation?.trim() ?? 'Member',
      isActive: true,
      createdAt: now,
      updatedAt: now,
      deviceId: _settings.deviceId,
    );
    _members.add(member);
    try {
      LocalDatabase.instance.insertMember(member);
    } catch (_) {}
    notifyListeners();
    return member;
  }

  void updateMember(Member updated) {
    final idx = _members.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _members[idx] = updated.copyWith(
        updatedAt: DateTime.now(),
        version: _members[idx].version + 1,
      );
      try {
        LocalDatabase.instance.insertMember(_members[idx]);
      } catch (_) {}
      notifyListeners();
    }
  }

  void toggleMemberActive(String memberId) {
    final idx = _members.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      _members[idx] = _members[idx].copyWith(
        isActive: !_members[idx].isActive,
        updatedAt: DateTime.now(),
        version: _members[idx].version + 1,
      );
      try {
        LocalDatabase.instance.insertMember(_members[idx]);
      } catch (_) {}
      notifyListeners();
    }
  }

  Member? getMember(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Member> getMembers(List<String> ids) {
    return _members.where((m) => ids.contains(m.id)).toList();
  }

  // --- Subtask & Query Helpers ---
  List<TaskItem> getSubtasks(String parentTaskId) {
    return _tasks.where((t) => t.parentTaskId == parentTaskId && !t.isDeleted).toList();
  }

  List<TaskItem> getMainTasks() {
    return _tasks.where((t) => t.isMainTask && !t.isDeleted).toList();
  }

  /// Carry-Forward tasks for active meeting (or a specific meeting):
  /// All Pending and In Progress tasks from past meetings (marked "carried from <date>")
  /// Plus any past tasks whose status was modified during this session.
  List<TaskItem> getCarriedForwardTasks({Meeting? targetMeeting}) {
    final refMeeting = targetMeeting ?? _activeMeeting;
    if (refMeeting == null) return [];

    return _tasks.where((t) {
      if (!t.isMainTask || t.isDeleted) return false;
      // Must not be a task originated in this meeting
      if (t.meetingId == refMeeting.id) return false;
      
      final wasModifiedInThisMeeting = _activityLogs.any(
        (l) => l.meetingId == refMeeting.id && (l.taskId == t.id || getSubtasks(t.id).any((s) => s.id == l.taskId)),
      );

      // Must be Pending or In Progress, or have work done in this session
      if (t.status != 'Pending' && t.status != 'In Progress' && !wasModifiedInThisMeeting) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Tasks introduced new in the current or target meeting
  List<TaskItem> getNewTasksForMeeting({Meeting? targetMeeting}) {
    final refMeeting = targetMeeting ?? _activeMeeting;
    if (refMeeting == null) return [];

    return _tasks.where((t) {
      if (!t.isMainTask || t.isDeleted) return false;
      return t.meetingId == refMeeting.id;
    }).toList();
  }

  /// All main tasks visible in meeting view:
  /// Includes New Tasks + Carried-Forward Tasks
  List<TaskItem> getAllMeetingTasks({Meeting? targetMeeting}) {
    final newTasks = getNewTasksForMeeting(targetMeeting: targetMeeting);
    final carriedTasks = getCarriedForwardTasks(targetMeeting: targetMeeting);
    
    // Combine without duplicates
    final Set<String> seenIds = {};
    final List<TaskItem> combined = [];
    for (final task in [...newTasks, ...carriedTasks]) {
      if (seenIds.add(task.id)) {
        combined.add(task);
      }
    }
    return combined;
  }

  /// Work done in a meeting (Activity Log of state changes)
  List<ActivityLog> getWorkDoneForMeeting(String meetingId) {
    return _activityLogs.where((l) => l.meetingId == meetingId && l.oldState != 'NEW').toList();
  }

  // Filtered Lists for Separate Views
  List<TaskItem> get pendingTasks => _tasks.where((t) => t.isMainTask && !t.isDeleted && t.status == 'Pending').toList();
  List<TaskItem> get inProgressTasks => _tasks.where((t) => t.isMainTask && !t.isDeleted && t.status == 'In Progress').toList();
  List<TaskItem> get completedTasks => _tasks.where((t) => t.isMainTask && !t.isDeleted && t.status == 'Completed').toList();
  List<TaskItem> get eliminatedTasks => _tasks.where((t) => t.isMainTask && !t.isDeleted && t.status == 'Eliminated').toList();

  void _logActivity({
    required String taskId,
    required String taskTitle,
    required String oldState,
    required String newState,
    required String note,
    bool isOverride = false,
    String? overrideReason,
    String? meetingId,
  }) {
    _activityLogs.insert(
      0,
      ActivityLog(
        id: _uuid.v4(),
        taskId: taskId,
        meetingId: meetingId,
        taskTitle: taskTitle,
        oldState: oldState,
        newState: newState,
        userId: _settings.currentUserId,
        userName: _settings.currentUserName,
        timestamp: DateTime.now(),
        note: note,
        isOverride: isOverride,
        overrideReason: overrideReason,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deviceId: _settings.deviceId,
      ),
    );
  }

  // Seed Institutional Demo Data
  void _initSeedData() {
    final now = DateTime.now();
    final pastDate1 = now.subtract(const Duration(days: 45));
    final pastDate2 = now.subtract(const Duration(days: 14));
    final today = DateTime(now.year, now.month, now.day);

    // 1. Members
    final m1 = Member(id: 'm-1', name: 'Dr. Evelyn Vance', email: 'vance@institution.gov', designation: 'Secretary-General', createdAt: pastDate1, updatedAt: pastDate1);
    final m2 = Member(id: 'm-2', name: 'Prof. Marcus Chen', email: 'chen@institution.gov', designation: 'Director of Technology', createdAt: pastDate1, updatedAt: pastDate1);
    final m3 = Member(id: 'm-3', name: 'Hon. Alistair Finch', email: 'finch@institution.gov', designation: 'Head of Audit & Compliance', createdAt: pastDate1, updatedAt: pastDate1);
    final m4 = Member(id: 'm-4', name: 'Sarah Jenkins, Esq.', email: 'jenkins@institution.gov', designation: 'Legal Counsel', createdAt: pastDate1, updatedAt: pastDate1);
    final m5 = Member(id: 'm-5', name: 'David Okafor', email: 'okafor@institution.gov', designation: 'Chief Operations Officer', createdAt: pastDate1, updatedAt: pastDate1);
    _members.addAll([m1, m2, m3, m4, m5]);

    // 2. Past Meetings
    final meet1 = Meeting(
      id: 'meet-01',
      meetingDate: pastDate1,
      title: 'Board of Governors Session XLVIII',
      attendeeMemberIds: [m1.id, m2.id, m3.id, m4.id],
      status: 'Adjourned',
      notes: 'Reviewed fiscal roadmap and security framework mandate.',
      createdAt: pastDate1,
      updatedAt: pastDate1,
    );

    final meet2 = Meeting(
      id: 'meet-02',
      meetingDate: pastDate2,
      title: 'Executive Council Bi-Weekly Review',
      attendeeMemberIds: [m1.id, m2.id, m5.id],
      status: 'Adjourned',
      notes: 'Monitored digital transformation rollout and campus audit.',
      createdAt: pastDate2,
      updatedAt: pastDate2,
    );

    // Active Meeting for Today
    final meet3 = Meeting(
      id: 'meet-03',
      meetingDate: today,
      title: 'Institutional Steering Committee - Regular Session',
      attendeeMemberIds: [m1.id, m2.id, m3.id, m4.id, m5.id],
      status: 'In Progress',
      notes: 'Convened to deliberate carried docket items and infrastructure directives.',
      createdAt: today,
      updatedAt: today,
    );

    _meetings.addAll([meet3, meet2, meet1]);
    _activeMeeting = meet3;

    // 3. Tasks from Past Meeting 1 (carried forward!)
    final t1 = TaskItem(
      id: 't-1',
      meetingId: meet1.id,
      title: 'Establish Central Institutional Repository and Disaster Recovery',
      description: 'Implement offline-capable synchronized storage for institutional proceedings.',
      status: 'In Progress',
      assignedMemberIds: [m2.id, m5.id],
      note: 'Hardware installed; database clustering currently undergoing penetration testing.',
      originMeetingDate: pastDate1,
      deadline: now.add(const Duration(days: 7)),
      createdAt: pastDate1,
      updatedAt: pastDate2,
    );

    final t1_sub1 = TaskItem(
      id: 't-1-s1',
      meetingId: meet1.id,
      parentTaskId: t1.id,
      title: 'Procure high-availability server cluster',
      status: 'Completed',
      assignedMemberIds: [m5.id],
      note: 'Dual rack units delivered and mounted in Vault B.',
      originMeetingDate: pastDate1,
      createdAt: pastDate1,
      updatedAt: pastDate1,
    );

    final t1_sub2 = TaskItem(
      id: 't-1-s2',
      meetingId: meet1.id,
      parentTaskId: t1.id,
      title: 'Configure automated PostgreSQL WAL replication',
      status: 'In Progress',
      assignedMemberIds: [m2.id],
      note: 'SSL certs verified; testing failover timing.',
      originMeetingDate: pastDate1,
      deadline: now.add(const Duration(days: 5)),
      createdAt: pastDate1,
      updatedAt: pastDate2,
    );

    // Task 2 from Past Meeting 2 (carried forward!)
    final t2 = TaskItem(
      id: 't-2',
      meetingId: meet2.id,
      title: 'Annual Statutory Governance Compliance Audit',
      description: 'Review committee charter and audit regulatory filings.',
      status: 'Pending',
      assignedMemberIds: [m3.id, m4.id],
      note: 'Awaiting certified filings from treasury sub-committee.',
      originMeetingDate: pastDate2,
      deadline: now.subtract(const Duration(days: 2)),
      createdAt: pastDate2,
      updatedAt: pastDate2,
    );

    final t2_sub1 = TaskItem(
      id: 't-2-s1',
      meetingId: meet2.id,
      parentTaskId: t2.id,
      title: 'Collate Q3 and Q4 committee voting minutes',
      status: 'Pending',
      assignedMemberIds: [m4.id],
      note: 'Draft transcripts gathered; awaiting final seal.',
      originMeetingDate: pastDate2,
      deadline: now.subtract(const Duration(days: 2)),
      createdAt: pastDate2,
      updatedAt: pastDate2,
    );

    // Task 3: Overridden Task (Demonstrating Force Complete)
    final t3 = TaskItem(
      id: 't-3',
      meetingId: meet1.id,
      title: 'Emergency Generator Overhaul & Fuel Line Certification',
      description: 'Inspect facility auxiliary turbine backup.',
      status: 'Completed',
      assignedMemberIds: [m5.id],
      note: 'Overridden by Secretary-General per Council Emergency Directive #104.',
      originMeetingDate: pastDate1,
      isOverridden: true,
      overrideReason: 'Executive Directive #104: Municipal grid certified stable; sub-turbine replacement deferred to 2027.',
      overrideBy: 'Dr. Evelyn Vance',
      overrideAt: pastDate2,
      createdAt: pastDate1,
      updatedAt: pastDate2,
    );

    final t3_sub1 = TaskItem(
      id: 't-3-s1',
      meetingId: meet1.id,
      parentTaskId: t3.id,
      title: 'Turbine blade ultrasound inspection',
      status: 'Eliminated',
      assignedMemberIds: [m5.id],
      note: 'Vendor contract terminated by mutual agreement.',
      originMeetingDate: pastDate1,
      createdAt: pastDate1,
      updatedAt: pastDate2,
    );

    // Task 4: New Task added in today's meeting
    final t4 = TaskItem(
      id: 't-4',
      meetingId: meet3.id,
      title: 'Implement Barcode Tracking for Physical Case Files',
      description: 'Replace manual paper sign-out register with laser barcode tracking.',
      status: 'In Progress',
      assignedMemberIds: [m1.id, m2.id],
      note: 'Pilot scanner units deployed to Archives Room 3.',
      originMeetingDate: today,
      createdAt: today,
      updatedAt: today,
    );

    final t4_sub1 = TaskItem(
      id: 't-4-s1',
      meetingId: meet3.id,
      parentTaskId: t4.id,
      title: 'Test Honeywell handheld scanner USB integration',
      status: 'Completed',
      assignedMemberIds: [m2.id],
      note: 'Scanners communicate via HID keyboard emulation cleanly.',
      originMeetingDate: today,
      createdAt: today,
      updatedAt: today,
    );

    final t4_sub2 = TaskItem(
      id: 't-4-s2',
      meetingId: meet3.id,
      parentTaskId: t4.id,
      title: 'Generate Code-128 label batch for archive dockets',
      status: 'In Progress',
      assignedMemberIds: [m1.id],
      note: 'Printed first test run of 500 vinyl adhesive labels.',
      originMeetingDate: today,
      createdAt: today,
      updatedAt: today,
    );

    // Task 5: Fully Completed Task
    final t5 = TaskItem(
      id: 't-5',
      meetingId: meet2.id,
      title: 'Secretariat SSL & DNS Shield Configuration',
      description: 'Configure Cloudflare proxy with Full SSL and strict TLS.',
      status: 'Completed',
      assignedMemberIds: [m2.id],
      note: 'Cloudflare edge certificates active; A records routed.',
      originMeetingDate: pastDate2,
      createdAt: pastDate2,
      updatedAt: pastDate2,
    );

    // Task 6: Eliminated Task
    final t6 = TaskItem(
      id: 't-6',
      meetingId: meet1.id,
      title: 'Procure Legacy Dot-Matrix Register Printers',
      description: 'Evaluate antique impact printing for multi-carbon forms.',
      status: 'Eliminated',
      assignedMemberIds: [m5.id],
      note: 'Discontinued due to lack of ribbon suppliers. Digital PDF adopted.',
      originMeetingDate: pastDate1,
      createdAt: pastDate1,
      updatedAt: pastDate1,
    );

    _tasks.addAll([t1, t1_sub1, t1_sub2, t2, t2_sub1, t3, t3_sub1, t4, t4_sub1, t4_sub2, t5, t6]);

    // 4. Activity Logs for "Work Done in this Meeting"
    _activityLogs.addAll([
      ActivityLog(
        id: 'act-1',
        taskId: t4_sub1.id,
        meetingId: meet3.id,
        taskTitle: 'Test Honeywell handheld scanner USB integration',
        oldState: 'Pending',
        newState: 'Completed',
        userId: m2.id,
        userName: m2.name,
        timestamp: today.add(const Duration(hours: 1)),
        note: 'Scanners communicate via HID keyboard emulation cleanly.',
        createdAt: today,
        updatedAt: today,
      ),
      ActivityLog(
        id: 'act-2',
        taskId: t4.id,
        meetingId: meet3.id,
        taskTitle: 'Implement Barcode Tracking for Physical Case Files',
        oldState: 'Pending',
        newState: 'In Progress',
        userId: m1.id,
        userName: m1.name,
        timestamp: today.add(const Duration(hours: 1, minutes: 15)),
        note: 'Pilot scanner units deployed to Archives Room 3.',
        createdAt: today,
        updatedAt: today,
      ),
      ActivityLog(
        id: 'act-3',
        taskId: t3.id,
        meetingId: meet2.id,
        taskTitle: 'Emergency Generator Overhaul & Fuel Line Certification',
        oldState: 'In Progress',
        newState: 'Completed',
        userId: m1.id,
        userName: m1.name,
        timestamp: pastDate2,
        note: 'Executive Directive #104: Municipal grid certified stable; sub-turbine replacement deferred to 2027.',
        isOverride: true,
        overrideReason: 'Executive Directive #104: Municipal grid certified stable; sub-turbine replacement deferred to 2027.',
        createdAt: pastDate2,
        updatedAt: pastDate2,
      ),
    ]);
  }
}
