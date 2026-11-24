import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import 'meeting_detail_screen.dart';

class PastMeetingsScreen extends StatelessWidget {
  const PastMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meetings = appState.meetings;

    return Container(
      color: InstitutionalTheme.creamBackground,
      child: Column(
        children: [
          // Header Ribbon
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
                      const Text(
                        'ARCHIVE OF PAST INSTITUTIONAL SESSIONS',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Preserved Proceedings, Minutes and Work-Done Registers (${meetings.length} Sessions on Record)',
                        style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Meetings List
          Expanded(
            child: meetings.isEmpty
                ? const Center(child: Text('No past meetings recorded in institutional archive.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      final meeting = meetings[index];
                      final isCurrentActive = appState.activeMeeting?.id == meeting.id;
                      final newTasks = appState.getNewTasksForMeeting(targetMeeting: meeting);
                      final carriedTasks = appState.getCarriedForwardTasks(targetMeeting: meeting);
                      final workDoneLogs = appState.getWorkDoneForMeeting(meeting.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: isCurrentActive ? InstitutionalTheme.goldAccent : InstitutionalTheme.borderLedger,
                            width: isCurrentActive ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              // Date Stamp Box
                              Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: InstitutionalTheme.creamSurface,
                                  border: Border.all(color: InstitutionalTheme.borderLedger),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('yyyy').format(meeting.meetingDate),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.goldDark),
                                    ),
                                    Text(
                                      DateFormat('MMM d').format(meeting.meetingDate).toUpperCase(),
                                      style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w800, color: InstitutionalTheme.primaryNavy),
                                    ),
                                    Text(
                                      DateFormat('EEEE').format(meeting.meetingDate),
                                      style: const TextStyle(fontSize: 10, color: InstitutionalTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),

                              // Meeting Information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          meeting.title.isNotEmpty ? meeting.title : 'Institutional Session',
                                          style: const TextStyle(
                                            fontFamily: 'serif',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: InstitutionalTheme.primaryNavy,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (isCurrentActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: InstitutionalTheme.statusCompleted, borderRadius: BorderRadius.circular(2)),
                                            child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      meeting.notes.isNotEmpty ? meeting.notes : 'Session minutes preserved in institutional repository.',
                                      style: const TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                                    ),
                                    const SizedBox(height: 10),
                                    // Counts row
                                    Row(
                                      children: [
                                        _badge('${newTasks.length} New Tasks', InstitutionalTheme.primaryNavy),
                                        const SizedBox(width: 8),
                                        _badge('${carriedTasks.length} Carried Tasks', InstitutionalTheme.goldDark),
                                        const SizedBox(width: 8),
                                        _badge('${workDoneLogs.length} Actions Logged', const Color(0xFF0F766E)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Open Details Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: InstitutionalTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => MeetingDetailScreen(meeting: meeting),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('OPEN PROCEEDINGS'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
