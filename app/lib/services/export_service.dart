import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/meeting_model.dart';
import '../models/task_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';

class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dateOnlyFormat = DateFormat('yyyy-MM-dd');

  // ============================================================================
  // 1. MEETING PROCEEDINGS EXPORT (EXCEL & PDF)
  // Mandated: Section A (New), Section B (Carried), Section C (Work Done)
  // ============================================================================

  /// Exports the meeting proceedings to Excel (.xlsx) with 3 distinct sections
  static Future<String> exportMeetingToExcel({
    required Meeting meeting,
    required List<TaskItem> newTasks,
    required List<TaskItem> carriedTasks,
    required List<ActivityLog> workDoneLogs,
    required List<Member> members,
  }) async {
    final excel = Excel.createExcel();
    final meetingDateStr = _dateOnlyFormat.format(meeting.meetingDate);

    // Sheet 1: Executive Session Summary
    final summarySheet = excel['Session Summary'];
    excel.setDefaultSheet('Session Summary');
    summarySheet.appendRow([TextCellValue('INSTITUTIONAL MEETING PROCEEDINGS - EXECUTIVE SUMMARY')]);
    summarySheet.appendRow([TextCellValue('Meeting Date:'), TextCellValue(meetingDateStr)]);
    summarySheet.appendRow([TextCellValue('Title:'), TextCellValue(meeting.title)]);
    summarySheet.appendRow([TextCellValue('Session Status:'), TextCellValue(meeting.status)]);
    summarySheet.appendRow([TextCellValue('Total Attendees:'), IntCellValue(meeting.attendeeMemberIds.length)]);
    summarySheet.appendRow([TextCellValue('Notes / Minutes:'), TextCellValue(meeting.notes)]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Section A (New Tasks Count):'),
      IntCellValue(newTasks.length)
    ]);
    summarySheet.appendRow([
      TextCellValue('Section B (Carried Forward Count):'),
      IntCellValue(carriedTasks.length)
    ]);
    summarySheet.appendRow([
      TextCellValue('Section C (Work Done State Changes):'),
      IntCellValue(workDoneLogs.length)
    ]);

    // Sheet 2: Section A - New Tasks
    final newTasksSheet = excel['Section A - New Tasks'];
    newTasksSheet.appendRow([
      TextCellValue('Docket ID'),
      TextCellValue('Task Title'),
      TextCellValue('Hierarchy'),
      TextCellValue('Status'),
      TextCellValue('Assigned Members'),
      TextCellValue('Initiate Date'),
      TextCellValue('Deadline'),
      TextCellValue('Deadline Status'),
      TextCellValue('Docket Note'),
    ]);
    for (final task in newTasks) {
      final assigneeNames = task.assignedMemberIds.map((id) {
        final m = members.where((mem) => mem.id == id).firstOrNull;
        return m?.name ?? id;
      }).join(', ');

      final deadlineStatus = task.deadline == null
          ? 'No Deadline'
          : (task.isOverdue
              ? 'OVERDUE (${-task.daysUntilDeadline!}d)'
              : (task.isDueToday ? 'DUE TODAY' : 'Due in ${task.daysUntilDeadline}d'));

      newTasksSheet.appendRow([
        TextCellValue(task.id),
        TextCellValue(task.isMainTask ? 'Main Task' : 'Subtask'),
        TextCellValue(task.title),
        TextCellValue(task.status),
        TextCellValue(assigneeNames),
        TextCellValue(_dateOnlyFormat.format(task.initiateDate)),
        TextCellValue(task.deadline != null ? _dateOnlyFormat.format(task.deadline!) : 'None'),
        TextCellValue(deadlineStatus),
        TextCellValue(task.note),
      ]);
    }

    // Sheet 3: Section B - Carried Forward Tasks
    final carriedSheet = excel['Section B - Carried Forward'];
    carriedSheet.appendRow([
      TextCellValue('Docket ID'),
      TextCellValue('Task Title'),
      TextCellValue('Status'),
      TextCellValue('Assigned Members'),
      TextCellValue('Initiate Date'),
      TextCellValue('Origin Session Date'),
      TextCellValue('Deadline'),
      TextCellValue('Deadline Status'),
      TextCellValue('Docket Note'),
    ]);
    for (final task in carriedTasks) {
      final assigneeNames = task.assignedMemberIds.map((id) {
        final m = members.where((mem) => mem.id == id).firstOrNull;
        return m?.name ?? id;
      }).join(', ');

      final deadlineStatus = task.deadline == null
          ? 'No Deadline'
          : (task.isOverdue
              ? 'OVERDUE (${-task.daysUntilDeadline!}d)'
              : (task.isDueToday ? 'DUE TODAY' : 'Due in ${task.daysUntilDeadline}d'));

      carriedSheet.appendRow([
        TextCellValue(task.id),
        TextCellValue(task.title),
        TextCellValue(task.status),
        TextCellValue(assigneeNames),
        TextCellValue(_dateOnlyFormat.format(task.initiateDate)),
        TextCellValue(_dateOnlyFormat.format(task.originMeetingDate)),
        TextCellValue(task.deadline != null ? _dateOnlyFormat.format(task.deadline!) : 'None'),
        TextCellValue(deadlineStatus),
        TextCellValue(task.note),
      ]);
    }

    // Sheet 4: Section C - Work Done During Session
    final workDoneSheet = excel['Section C - Work Done'];
    workDoneSheet.appendRow([
      TextCellValue('Timestamp'),
      TextCellValue('Task / Docket Item'),
      TextCellValue('Previous State'),
      TextCellValue('New State'),
      TextCellValue('Transition Details'),
      TextCellValue('Authorized Officer'),
      TextCellValue('Executive Override?'),
      TextCellValue('Override Justification'),
      TextCellValue('Recorded Note'),
    ]);
    for (final log in workDoneLogs) {
      workDoneSheet.appendRow([
        TextCellValue(_dateFormat.format(log.timestamp)),
        TextCellValue(log.taskTitle),
        TextCellValue(log.oldState),
        TextCellValue(log.newState),
        TextCellValue('${log.oldState} -> ${log.newState}'),
        TextCellValue(log.userName),
        TextCellValue(log.isOverride ? 'YES (OVERRIDE)' : 'No'),
        TextCellValue(log.overrideReason ?? ''),
        TextCellValue(log.note),
      ]);
    }

    final fileBytes = excel.save()!;
    final filename = 'Meeting_Proceedings_${meetingDateStr}_${meeting.id.substring(0, 8)}.xlsx';

    return await _saveFile(filename: filename, bytes: Uint8List.fromList(fileBytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
  }

  /// Exports the meeting proceedings to formal Institutional PDF
  static Future<void> exportMeetingToPdf({
    required Meeting meeting,
    required List<TaskItem> newTasks,
    required List<TaskItem> carriedTasks,
    required List<ActivityLog> workDoneLogs,
    required List<Member> members,
  }) async {
    final pdf = pw.Document();
    final meetingDateStr = _dateOnlyFormat.format(meeting.meetingDate);

    final navyColor = PdfColor.fromHex('#1F3A5F');
    final goldColor = PdfColor.fromHex('#B8923A');
    final creamBg = PdfColor.fromHex('#FAF7F0');
    final borderCol = PdfColor.fromHex('#DDD5C7');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderCol, width: 1))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('INSTITUTIONAL MEETING PROCEEDINGS & DOCKET RECORD', style: pw.TextStyle(color: navyColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('SESSION DATE: $meetingDateStr', style: pw.TextStyle(color: goldColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: borderCol, width: 0.5))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('OFFICIAL INSTITUTIONAL RECORD - AUDIT COMPLIANT', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: creamBg, border: pw.Border.all(color: borderCol)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  meeting.title.isNotEmpty ? meeting.title.toUpperCase() : 'EXECUTIVE COUNCIL SESSION',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: navyColor),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Text('Status: ${meeting.status.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: goldColor)),
                    pw.SizedBox(width: 20),
                    pw.Text('Attendees Recorded: ${meeting.attendeeMemberIds.length}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                if (meeting.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text('Minutes / Summary Notes: ${meeting.notes}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // SECTION A: NEW TASKS ADDED
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: navyColor,
            child: pw.Text('SECTION A: NEW TASKS ADDED IN THIS SESSION (${newTasks.length})', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          if (newTasks.isEmpty)
            pw.Text('No new tasks initiated during this session.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Type', 'Task Title', 'Status', 'Assignees', 'Initiated', 'Deadline', 'Notes'],
              data: newTasks.map((t) {
                final assignees = t.assignedMemberIds.map((id) => members.where((m) => m.id == id).firstOrNull?.name ?? id).join(', ');
                final deadlineText = t.deadline != null ? _dateOnlyFormat.format(t.deadline!) : '-';
                return [
                  t.isMainTask ? 'Main Task' : '  > Subtask',
                  t.title,
                  t.status,
                  assignees.isNotEmpty ? assignees : 'Unassigned',
                  _dateOnlyFormat.format(t.initiateDate),
                  deadlineText,
                  t.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: navyColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headerDecoration: pw.BoxDecoration(color: creamBg),
              border: pw.TableBorder.all(color: borderCol, width: 0.5),
            ),
          pw.SizedBox(height: 18),

          // SECTION B: CARRIED FORWARD TASKS
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: navyColor,
            child: pw.Text('SECTION B: PAST TASKS CARRIED FORWARD (${carriedTasks.length})', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          if (carriedTasks.isEmpty)
            pw.Text('No pending or in-progress tasks carried from prior sessions.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Task Title', 'Status', 'Origin Session', 'Deadline', 'Assignees', 'Docket Note'],
              data: carriedTasks.map((t) {
                final assignees = t.assignedMemberIds.map((id) => members.where((m) => m.id == id).firstOrNull?.name ?? id).join(', ');
                final deadlineText = t.deadline != null ? _dateOnlyFormat.format(t.deadline!) : '-';
                return [
                  t.title,
                  t.status,
                  _dateOnlyFormat.format(t.originMeetingDate),
                  deadlineText,
                  assignees.isNotEmpty ? assignees : 'Unassigned',
                  t.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: navyColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headerDecoration: pw.BoxDecoration(color: creamBg),
              border: pw.TableBorder.all(color: borderCol, width: 0.5),
            ),
          pw.SizedBox(height: 18),

          // SECTION C: WORK DONE IN THIS MEETING
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: navyColor,
            child: pw.Text('SECTION C: WORK DONE & STATE TRANSITIONS LOG (${workDoneLogs.length})', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          if (workDoneLogs.isEmpty)
            pw.Text('No task status mutations occurred during this session.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Timestamp', 'Task Name', 'State Transition', 'Officer', 'Override?', 'Note'],
              data: workDoneLogs.map((log) {
                return [
                  _dateFormat.format(log.timestamp),
                  log.taskTitle,
                  '${log.oldState} -> ${log.newState}',
                  log.userName,
                  log.isOverride ? 'OVERRIDE' : '-',
                  log.note.isNotEmpty ? log.note : (log.overrideReason ?? ''),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: navyColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: creamBg),
              border: pw.TableBorder.all(color: borderCol, width: 0.5),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Meeting_Proceedings_$meetingDateStr.pdf',
    );
  }

  // ============================================================================
  // 2. MASTER TASK LEDGER EXPORT (EXCEL & PDF)
  // Mandated: All task ledger need as exportable
  // ============================================================================

  /// Exports the complete Task Ledger to Excel (.xlsx)
  static Future<String> exportTaskLedgerToExcel({
    required List<TaskItem> tasks,
    required List<Member> members,
    String filterName = 'ALL',
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Master Task Ledger'];
    excel.setDefaultSheet('Master Task Ledger');

    sheet.appendRow([TextCellValue('OFFICIAL INSTITUTIONAL MASTER TASK LEDGER')]);
    sheet.appendRow([
      TextCellValue('Export Timestamp:'),
      TextCellValue(_dateFormat.format(DateTime.now())),
      TextCellValue('Filter:'),
      TextCellValue(filterName),
      TextCellValue('Total Records:'),
      IntCellValue(tasks.length),
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Table Header
    sheet.appendRow([
      TextCellValue('Record ID'),
      TextCellValue('Level'),
      TextCellValue('Title / Description'),
      TextCellValue('Status'),
      TextCellValue('Assigned Members'),
      TextCellValue('Initiate Date'),
      TextCellValue('Deadline'),
      TextCellValue('Deadline Status'),
      TextCellValue('Origin Session Date'),
      TextCellValue('Last Updated'),
      TextCellValue('Is Overridden?'),
      TextCellValue('Override Reason'),
      TextCellValue('Docket Note'),
    ]);

    for (final task in tasks) {
      final assigneeNames = task.assignedMemberIds.map((id) {
        final m = members.where((mem) => mem.id == id).firstOrNull;
        return m?.name ?? id;
      }).join(', ');

      final deadlineStatus = task.deadline == null
          ? 'No Deadline'
          : (task.isOverdue
              ? 'OVERDUE (${-task.daysUntilDeadline!}d)'
              : (task.isDueToday ? 'DUE TODAY' : 'Due in ${task.daysUntilDeadline}d'));

      sheet.appendRow([
        TextCellValue(task.id),
        TextCellValue(task.isMainTask ? 'Main Task' : 'Subtask'),
        TextCellValue(task.title),
        TextCellValue(task.status),
        TextCellValue(assigneeNames),
        TextCellValue(_dateOnlyFormat.format(task.initiateDate)),
        TextCellValue(task.deadline != null ? _dateOnlyFormat.format(task.deadline!) : 'None'),
        TextCellValue(deadlineStatus),
        TextCellValue(_dateOnlyFormat.format(task.originMeetingDate)),
        TextCellValue(_dateFormat.format(task.updatedAt)),
        TextCellValue(task.isOverridden ? 'YES' : 'NO'),
        TextCellValue(task.overrideReason ?? ''),
        TextCellValue(task.note),
      ]);
    }

    final fileBytes = excel.save()!;
    final filename = 'Task_Ledger_Export_${_dateOnlyFormat.format(DateTime.now())}.xlsx';
    return await _saveFile(filename: filename, bytes: Uint8List.fromList(fileBytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
  }

  /// Exports the complete Task Ledger to print-ready PDF
  static Future<void> exportTaskLedgerToPdf({
    required List<TaskItem> tasks,
    required List<Member> members,
    String filterName = 'ALL',
  }) async {
    final pdf = pw.Document();
    final navyColor = PdfColor.fromHex('#1F3A5F');
    final goldColor = PdfColor.fromHex('#B8923A');
    final creamBg = PdfColor.fromHex('#FAF7F0');
    final borderCol = PdfColor.fromHex('#DDD5C7');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderCol, width: 1))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('INSTITUTIONAL MASTER DOCKET LEDGER REGISTER', style: pw.TextStyle(color: navyColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('SCOPE: $filterName | TOTAL RECORDS: ${tasks.length}', style: pw.TextStyle(color: goldColor, fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: borderCol, width: 0.5))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('CONFIDENTIAL INSTITUTIONAL RECORD', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.TableHelper.fromTextArray(
            headers: ['Level', 'Task Title', 'Status', 'Assigned Members', 'Initiated', 'Deadline', 'Override?', 'Note'],
            data: tasks.map((t) {
              final assignees = t.assignedMemberIds.map((id) => members.where((m) => m.id == id).firstOrNull?.name ?? id).join(', ');
              final deadlineText = t.deadline != null ? _dateOnlyFormat.format(t.deadline!) : '-';
              return [
                t.isMainTask ? 'MAIN' : '  > SUB',
                t.title,
                t.status,
                assignees.isNotEmpty ? assignees : 'Unassigned',
                _dateOnlyFormat.format(t.initiateDate),
                deadlineText,
                t.isOverridden ? 'OVERRIDE' : '-',
                t.note,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: navyColor),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headerDecoration: pw.BoxDecoration(color: creamBg),
            border: pw.TableBorder.all(color: borderCol, width: 0.5),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Task_Ledger_${_dateOnlyFormat.format(DateTime.now())}.pdf',
    );
  }

  // ============================================================================
  // 3. STATISTICAL & EXECUTIVE REPORTS EXPORT (EXCEL & PDF)
  // Mandated: 1, 2, 3, 6, 12 month reports with counts, completion rate, member workload
  // ============================================================================

  /// Exports executive period report to Excel
  static Future<String> exportReportToExcel({
    required int months,
    required List<TaskItem> periodTasks,
    required List<TaskItem> longPendingTasks,
    required List<Member> members,
    required String completionRate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Executive Audit Metrics'];
    excel.setDefaultSheet('Executive Audit Metrics');

    final pendingCount = periodTasks.where((t) => t.status == 'Pending').length;
    final inProgressCount = periodTasks.where((t) => t.status == 'In Progress').length;
    final completedCount = periodTasks.where((t) => t.status == 'Completed').length;
    final eliminatedCount = periodTasks.where((t) => t.status == 'Eliminated').length;

    sheet.appendRow([TextCellValue('EXECUTIVE STATISTICAL & DOCKET VELOCITY REPORT')]);
    sheet.appendRow([TextCellValue('Audit Horizon:'), TextCellValue('$months Months Window')]);
    sheet.appendRow([TextCellValue('Report Date:'), TextCellValue(_dateFormat.format(DateTime.now()))]);
    sheet.appendRow([TextCellValue('Total Docket Tasks:'), IntCellValue(periodTasks.length)]);
    sheet.appendRow([TextCellValue('Completion Velocity:'), TextCellValue('$completionRate %')]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('STATUS BREAKDOWN')]);
    sheet.appendRow([TextCellValue('Completed:'), IntCellValue(completedCount)]);
    sheet.appendRow([TextCellValue('Pending:'), IntCellValue(pendingCount)]);
    sheet.appendRow([TextCellValue('In Progress:'), IntCellValue(inProgressCount)]);
    sheet.appendRow([TextCellValue('Eliminated:'), IntCellValue(eliminatedCount)]);
    sheet.appendRow([TextCellValue('')]);

    // Member Workload Sheet
    final workloadSheet = excel['Member Workload'];
    workloadSheet.appendRow([
      TextCellValue('Member Name'),
      TextCellValue('Designation'),
      TextCellValue('Total Assigned Tasks'),
      TextCellValue('Completed Tasks'),
      TextCellValue('In Progress Tasks'),
      TextCellValue('Pending Tasks'),
    ]);

    for (final member in members) {
      final assigned = periodTasks.where((t) => t.assignedMemberIds.contains(member.id)).toList();
      workloadSheet.appendRow([
        TextCellValue(member.name),
        TextCellValue(member.designation),
        IntCellValue(assigned.length),
        IntCellValue(assigned.where((t) => t.status == 'Completed').length),
        IntCellValue(assigned.where((t) => t.status == 'In Progress').length),
        IntCellValue(assigned.where((t) => t.status == 'Pending').length),
      ]);
    }

    // Long Pending Sheet
    final longPendingSheet = excel['Long Pending Tasks (>14 Days)'];
    longPendingSheet.appendRow([
      TextCellValue('Task Title'),
      TextCellValue('Status'),
      TextCellValue('Created At'),
      TextCellValue('Days Dormant'),
      TextCellValue('Docket Note'),
    ]);
    for (final t in longPendingTasks) {
      final days = DateTime.now().difference(t.createdAt).inDays;
      longPendingSheet.appendRow([
        TextCellValue(t.title),
        TextCellValue(t.status),
        TextCellValue(_dateFormat.format(t.createdAt)),
        IntCellValue(days),
        TextCellValue(t.note),
      ]);
    }

    final fileBytes = excel.save()!;
    final filename = 'Executive_Audit_Report_${months}M_${_dateOnlyFormat.format(DateTime.now())}.xlsx';
    return await _saveFile(filename: filename, bytes: Uint8List.fromList(fileBytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
  }

  /// Exports executive period report to PDF
  static Future<void> exportReportToPdf({
    required int months,
    required List<TaskItem> periodTasks,
    required List<TaskItem> longPendingTasks,
    required List<Member> members,
    required String completionRate,
  }) async {
    final pdf = pw.Document();
    final navyColor = PdfColor.fromHex('#1F3A5F');
    final goldColor = PdfColor.fromHex('#B8923A');
    final creamBg = PdfColor.fromHex('#FAF7F0');
    final borderCol = PdfColor.fromHex('#DDD5C7');

    final pendingCount = periodTasks.where((t) => t.status == 'Pending').length;
    final inProgressCount = periodTasks.where((t) => t.status == 'In Progress').length;
    final completedCount = periodTasks.where((t) => t.status == 'Completed').length;
    final eliminatedCount = periodTasks.where((t) => t.status == 'Eliminated').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderCol, width: 1))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('EXECUTIVE STATISTICAL & PROGRESS AUDIT REPORT', style: pw.TextStyle(color: navyColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('$months-MONTH HORIZON', style: pw.TextStyle(color: goldColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: creamBg, border: pw.Border.all(color: borderCol)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfMetric('TOTAL TASKS', '${periodTasks.length}', navyColor),
                _buildPdfMetric('COMPLETED', '$completedCount', PdfColor.fromHex('#16A34A')),
                _buildPdfMetric('IN PROGRESS', '$inProgressCount', PdfColor.fromHex('#CA8A04')),
                _buildPdfMetric('PENDING', '$pendingCount', PdfColor.fromHex('#7C3AED')),
                _buildPdfMetric('ELIMINATED', '$eliminatedCount', PdfColor.fromHex('#DC2626')),
                _buildPdfMetric('COMPLETION RATE', '$completionRate%', goldColor),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Member Workload Table
          pw.Text('MEMBER WORKLOAD ALLOCATION', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: navyColor)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Member Name', 'Designation', 'Assigned', 'Completed', 'In Progress', 'Pending'],
            data: members.map((m) {
              final assigned = periodTasks.where((t) => t.assignedMemberIds.contains(m.id)).toList();
              return [
                m.name,
                m.designation,
                '${assigned.length}',
                '${assigned.where((t) => t.status == 'Completed').length}',
                '${assigned.where((t) => t.status == 'In Progress').length}',
                '${assigned.where((t) => t.status == 'Pending').length}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: navyColor),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: creamBg),
            border: pw.TableBorder.all(color: borderCol, width: 0.5),
          ),
          pw.SizedBox(height: 20),

          // Long Pending Items
          pw.Text('CRITICAL LONG-PENDING ITEMS (> 14 DAYS DORMANT)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#DC2626'))),
          pw.SizedBox(height: 8),
          if (longPendingTasks.isEmpty)
            pw.Text('No dormant tasks exceeding 14 days.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Task Title', 'Status', 'Days Dormant', 'Docket Note'],
              data: longPendingTasks.map((t) {
                final days = DateTime.now().difference(t.createdAt).inDays;
                return [
                  t.title,
                  t.status,
                  '$days days',
                  t.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: navyColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: creamBg),
              border: pw.TableBorder.all(color: borderCol, width: 0.5),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Audit_Report_${months}M_${_dateOnlyFormat.format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildPdfMetric(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
      ],
    );
  }

  /// Internal file saver helper supporting Web, Desktop and Mobile
  static Future<String> _saveFile({
    required String filename,
    required Uint8List bytes,
    required String ext,
    required MimeType mimeType,
  }) async {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // Save directly to user documents / downloads directory
        final dir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(p.join(dir.path, 'MeetingTracker_Exports'));
        if (!exportDir.existsSync()) {
          exportDir.createSync(recursive: true);
        }
        final filePath = p.join(exportDir.path, filename);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        debugPrint('[FILE EXPORT SUCCESS] Saved to $filePath');
        return filePath;
      } else {
        // Browser or Mobile
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: ext,
          mimeType: mimeType,
        );
        return filename;
      }
    } catch (e) {
      debugPrint('[FILE SAVER FALLBACK] $e');
      return filename;
    }
  }
}
