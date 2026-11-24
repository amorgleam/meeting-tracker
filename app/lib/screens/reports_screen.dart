import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../widgets/status_chip.dart';
import '../models/task_model.dart';
import '../models/member_model.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedMonths = 1; // 1, 2, 3, 6, 12

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - _selectedMonths, now.day);

    // Filter main tasks within period
    final periodTasks = appState.getMainTasks().where((t) {
      return t.createdAt.isAfter(cutoffDate);
    }).toList();

    final pendingCount = periodTasks.where((t) => t.status == 'Pending').length;
    final inProgressCount = periodTasks.where((t) => t.status == 'In Progress').length;
    final completedCount = periodTasks.where((t) => t.status == 'Completed').length;
    final eliminatedCount = periodTasks.where((t) => t.status == 'Eliminated').length;
    final totalCount = periodTasks.length;

    final completionRate = totalCount > 0 ? ((completedCount / totalCount) * 100).toStringAsFixed(1) : '0.0';

    // Long pending tasks (> 14 days)
    final longPendingCutoff = now.subtract(const Duration(days: 14));
    final longPendingTasks = appState.pendingTasks.where((t) => t.createdAt.isBefore(longPendingCutoff)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  color: InstitutionalTheme.primaryNavy,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assessment, color: InstitutionalTheme.goldAccent, size: 26),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXECUTIVE STATISTICAL & PROGRESS AUDIT REPORT',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: InstitutionalTheme.creamBackground,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Institutional Performance Metrics, Member Workload and Docket Velocity',
                            style: TextStyle(fontSize: 11.5, color: InstitutionalTheme.goldLight),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: InstitutionalTheme.goldAccent,
                        foregroundColor: InstitutionalTheme.primaryNavy,
                      ),
                      onPressed: () => _showExportReportDialog(
                        context: context,
                        months: _selectedMonths,
                        periodTasks: periodTasks,
                        longPendingTasks: longPendingTasks,
                        members: appState.members,
                        completionRate: completionRate,
                      ),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('EXPORT REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: InstitutionalTheme.creamCard,
                  border: Border.all(color: InstitutionalTheme.borderLedger),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PERIOD SELECTOR
                    Row(
                      children: [
                        const Text(
                          'AUDIT TIMEFRAME:',
                          style: TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                        ),
                        const SizedBox(width: 14),
                        ...[
                          {'months': 1, 'label': '1 Month (Monthly)'},
                          {'months': 2, 'label': '2 Months'},
                          {'months': 3, 'label': '3 Months (Quarterly)'},
                          {'months': 6, 'label': '6 Months (Biannual)'},
                          {'months': 12, 'label': '12 Months (Annual)'},
                        ].map((p) {
                          final isSelected = _selectedMonths == p['months'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(p['label'] as String),
                              selected: isSelected,
                              selectedColor: InstitutionalTheme.primaryNavy,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : InstitutionalTheme.textDark,
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedMonths = p['months'] as int);
                              },
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // EXECUTIVE KPI CARDS
                    Row(
                      children: [
                        _buildKpiCard('TOTAL TASKS', '$totalCount', 'Introduced in period', InstitutionalTheme.primaryNavy),
                        const SizedBox(width: 12),
                        _buildKpiCard('COMPLETION RATE', '$completionRate%', '$completedCount of $totalCount completed', InstitutionalTheme.statusCompleted),
                        const SizedBox(width: 12),
                        _buildKpiCard('IN PROGRESS', '$inProgressCount', 'Active execution', InstitutionalTheme.statusInProgress),
                        const SizedBox(width: 12),
                        _buildKpiCard('PENDING DOCKET', '$pendingCount', 'Awaiting action', InstitutionalTheme.statusPending),
                        const SizedBox(width: 12),
                        _buildKpiCard('ELIMINATED', '$eliminatedCount', 'Cancelled / dropped', InstitutionalTheme.statusEliminated),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),

                    // MEMBER WORKLOAD REGISTER
                    const Text(
                      'MEMBER WORKLOAD & PERFORMANCE LEDGER',
                      style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: InstitutionalTheme.borderLedger),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Table(
                        border: TableBorder.all(color: InstitutionalTheme.borderLedger, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.2),
                          4: FlexColumnWidth(1.2),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: InstitutionalTheme.creamSurface),
                            children: [
                              _TableHeader('MEMBER / OFFICE'),
                              _TableHeader('TOTAL ASSIGNED'),
                              _TableHeader('COMPLETED'),
                              _TableHeader('IN PROGRESS'),
                              _TableHeader('PENDING'),
                            ],
                          ),
                          ...appState.members.where((m) => m.isActive).map((member) {
                            final memberTasks = appState.tasks.where((t) => !t.isDeleted && t.assignedMemberIds.contains(member.id)).toList();
                            final mComp = memberTasks.where((t) => t.status == 'Completed').length;
                            final mProg = memberTasks.where((t) => t.status == 'In Progress').length;
                            final mPend = memberTasks.where((t) => t.status == 'Pending').length;

                            return TableRow(
                              children: [
                                _TableCell('${member.name} (${member.designation})', isBold: true),
                                _TableCell('${memberTasks.length}', align: TextAlign.center),
                                _TableCell('$mComp', align: TextAlign.center, color: InstitutionalTheme.statusCompleted),
                                _TableCell('$mProg', align: TextAlign.center, color: InstitutionalTheme.statusInProgress),
                                _TableCell('$mPend', align: TextAlign.center, color: InstitutionalTheme.statusPending),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),

                    // LONG-PENDING TASKS REGISTER (> 14 DAYS)
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: InstitutionalTheme.statusPending),
                        const SizedBox(width: 8),
                        Text(
                          'LONG-PENDING DOCKET ITEMS (> 14 DAYS UNRESOLVED) - ${longPendingTasks.length} ENTRIES',
                          style: const TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (longPendingTasks.isEmpty)
                      const Text('No long-pending tasks currently overdue.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: InstitutionalTheme.borderLedger),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: longPendingTasks.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final task = longPendingTasks[i];
                            final daysPending = now.difference(task.createdAt).inDays;
                            final originStr = DateFormat('yyyy-MM-dd').format(task.originMeetingDate);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '$daysPending DAYS PENDING',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: InstitutionalTheme.statusEliminated),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(task.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy)),
                                        Text('Originated in session: $originStr', style: const TextStyle(fontSize: 11, color: InstitutionalTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  StatusChip(status: task.status, isCompact: true),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: InstitutionalTheme.borderLedger),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: InstitutionalTheme.textMuted)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: InstitutionalTheme.textBody)),
          ],
        ),
      ),
    );
  }

  void _showExportReportDialog({
    required BuildContext context,
    required int months,
    required List<TaskItem> periodTasks,
    required List<TaskItem> longPendingTasks,
    required List<Member> members,
    required String completionRate,
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
              child: const Icon(Icons.assessment, color: InstitutionalTheme.goldDark, size: 20),
            ),
            const SizedBox(width: 10),
            Text('EXPORT $months-MONTH AUDIT REPORT', style: const TextStyle(fontFamily: 'serif', fontSize: 16, color: InstitutionalTheme.primaryNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate an executive audit package for the $months-month window (${periodTasks.length} tasks recorded, $completionRate% completion velocity):',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
              leading: const Icon(Icons.table_chart, color: Color(0xFF16A34A)),
              title: const Text('Export to Microsoft Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Metrics breakdown, Member Workload sheet & Dormant Tasks sheet', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  final path = await ExportService.exportReportToExcel(
                    months: months,
                    periodTasks: periodTasks,
                    longPendingTasks: longPendingTasks,
                    members: members,
                    completionRate: completionRate,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Executive Report successfully exported to Excel!\nFile: $path'),
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
              subtitle: const Text('Formal executive scorecard with summary metrics, member workload & audit flags', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await ExportService.exportReportToPdf(
                    months: months,
                    periodTasks: periodTasks,
                    longPendingTasks: longPendingTasks,
                    members: members,
                    completionRate: completionRate,
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

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'serif', fontSize: 11.5, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy, letterSpacing: 0.5),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final TextAlign align;
  final Color? color;

  const _TableCell(this.text, {this.isBold = false, this.align = TextAlign.left, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: color ?? InstitutionalTheme.textDark,
        ),
      ),
    );
  }
}
