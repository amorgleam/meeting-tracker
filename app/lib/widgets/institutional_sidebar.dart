import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';

class InstitutionalSidebar extends StatelessWidget {
  const InstitutionalSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final pendingCount = appState.pendingTasks.length;
    final inProgressCount = appState.inProgressTasks.length;
    final completedCount = appState.completedTasks.length;
    final eliminatedCount = appState.eliminatedTasks.length;

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: InstitutionalTheme.primaryNavy,
        border: Border(
          right: BorderSide(color: InstitutionalTheme.goldDark, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Institutional Crest & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x33B8923A), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x22B8923A),
                    border: Border.all(color: InstitutionalTheme.goldAccent, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: InstitutionalTheme.goldAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEETING TRACKER',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: InstitutionalTheme.creamBackground,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Office of the Secretariat',
                        style: TextStyle(
                          fontSize: 11,
                          color: InstitutionalTheme.goldLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _navSectionHeader('GOVERNANCE SESSIONS'),
                _navItem(
                  context,
                  index: 0,
                  icon: Icons.meeting_room_outlined,
                  label: appState.activeMeeting != null ? 'Active Meeting' : 'Convene Meeting',
                  isSelected: appState.selectedNavIndex == 0,
                  badge: appState.activeMeeting != null ? 'LIVE' : null,
                  badgeColor: InstitutionalTheme.statusCompleted,
                ),
                _navItem(
                  context,
                  index: 1,
                  icon: Icons.history_edu_outlined,
                  label: 'Past Meetings Archive',
                  isSelected: appState.selectedNavIndex == 1,
                ),

                const SizedBox(height: 12),
                _navSectionHeader('DOCKET & REGISTERS'),
                _navItem(
                  context,
                  index: 2,
                  icon: Icons.view_list_outlined,
                  label: 'All Tasks Ledger',
                  isSelected: appState.selectedNavIndex == 2,
                ),
                _navItem(
                  context,
                  index: 3,
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending Tasks',
                  isSelected: appState.selectedNavIndex == 3,
                  badge: pendingCount.toString(),
                  badgeColor: InstitutionalTheme.statusPending,
                ),
                _navItem(
                  context,
                  index: 4,
                  icon: Icons.rotate_right_outlined,
                  label: 'In Progress Tasks',
                  isSelected: appState.selectedNavIndex == 4,
                  badge: inProgressCount.toString(),
                  badgeColor: InstitutionalTheme.statusInProgress,
                ),
                _navItem(
                  context,
                  index: 5,
                  icon: Icons.task_alt_outlined,
                  label: 'Completed Tasks',
                  isSelected: appState.selectedNavIndex == 5,
                  badge: completedCount.toString(),
                  badgeColor: InstitutionalTheme.statusCompleted,
                ),
                _navItem(
                  context,
                  index: 6,
                  icon: Icons.cancel_outlined,
                  label: 'Eliminated Tasks',
                  isSelected: appState.selectedNavIndex == 6,
                  badge: eliminatedCount.toString(),
                  badgeColor: InstitutionalTheme.statusEliminated,
                ),

                const SizedBox(height: 12),
                _navSectionHeader('INSTITUTIONAL ADMINISTRATION'),
                _navItem(
                  context,
                  index: 7,
                  icon: Icons.people_alt_outlined,
                  label: 'Members Roster',
                  isSelected: appState.selectedNavIndex == 7,
                ),
                _navItem(
                  context,
                  index: 8,
                  icon: Icons.analytics_outlined,
                  label: 'Executive Reports',
                  isSelected: appState.selectedNavIndex == 8,
                ),
                _navItem(
                  context,
                  index: 9,
                  icon: Icons.tune_outlined,
                  label: 'Admin Settings',
                  isSelected: appState.selectedNavIndex == 9,
                ),
              ],
            ),
          ),

          // User Profile & Offline Sync Pill
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: InstitutionalTheme.navyDark,
              border: Border(
                top: BorderSide(color: Color(0x33B8923A), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: InstitutionalTheme.goldAccent,
                      child: Text(
                        appState.settings.currentUserName.isNotEmpty ? appState.settings.currentUserName[0] : 'U',
                        style: const TextStyle(
                          color: InstitutionalTheme.primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.settings.currentUserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'ROLE: ${appState.settings.userRole.toUpperCase()}',
                            style: const TextStyle(
                              color: InstitutionalTheme.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1A22C55E),
                    border: Border.all(color: const Color(0x4422C55E), width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_outlined, size: 12, color: Color(0xFF86EFAC)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'OFFLINE-FIRST (DRIFT SQLITE)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0x88FAF7F0),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    String? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: () {
        context.read<AppState>().setNavIndex(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x33B8923A) : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? InstitutionalTheme.goldAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? InstitutionalTheme.goldAccent : InstitutionalTheme.creamBackground.withOpacity(0.85),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : InstitutionalTheme.creamBackground.withOpacity(0.9),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? InstitutionalTheme.goldAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: (badgeColor == InstitutionalTheme.statusInProgress) ? Colors.black : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
