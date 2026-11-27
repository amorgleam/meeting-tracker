import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/institutional_sidebar.dart';
import '../widgets/institutional_app_bar.dart';
import '../widgets/institutional_bottom_nav.dart';
import 'active_meeting_screen.dart';
import 'start_meeting_screen.dart';
import 'past_meetings_screen.dart';
import 'task_ledger_screen.dart';
import 'members_screen.dart';
import 'reports_screen.dart';
import 'admin_settings_screen.dart';
import 'account_activities_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 820;

        Widget content;
        switch (appState.selectedNavIndex) {
          case 0:
            content = appState.activeMeeting != null
                ? const ActiveMeetingScreen()
                : const StartMeetingScreen();
            break;
          case 1:
            content = const PastMeetingsScreen();
            break;
          case 2:
            content = const TaskLedgerScreen(filter: 'ALL', title: 'All Institutional Tasks Ledger');
            break;
          case 3:
            content = const TaskLedgerScreen(filter: 'PENDING', title: 'Pending Tasks Register');
            break;
          case 4:
            content = const TaskLedgerScreen(filter: 'IN_PROGRESS', title: 'In Progress Tasks Register');
            break;
          case 5:
            content = const TaskLedgerScreen(filter: 'COMPLETED', title: 'Completed Tasks Register');
            break;
          case 6:
            content = const TaskLedgerScreen(filter: 'ELIMINATED', title: 'Eliminated Tasks Register');
            break;
          case 7:
            content = const MembersScreen();
            break;
          case 8:
            content = const ReportsScreen();
            break;
          case 9:
            content = appState.isAdmin
                ? const AdminSettingsScreen()
                : (appState.activeMeeting != null
                    ? const ActiveMeetingScreen()
                    : const StartMeetingScreen());
            break;
          case 10:
            content = appState.isAdmin
                ? const AccountActivitiesScreen()
                : (appState.activeMeeting != null
                    ? const ActiveMeetingScreen()
                    : const StartMeetingScreen());
            break;
          default:
            content = const ActiveMeetingScreen();
        }

        if (isDesktop) {
          // Windows Desktop: Classical Sidebar Navigation + Wide Ledger Table Views
          return Scaffold(
            body: Row(
              children: [
                const InstitutionalSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      InstitutionalAppBar(
                        title: _getTitle(appState.selectedNavIndex, appState.activeMeeting != null, appState.isAdmin),
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Android / Mobile: Bottom Navigation Bar + Institutional Docket Cards
          return Scaffold(
            appBar: InstitutionalAppBar(
              title: _getTitle(appState.selectedNavIndex, appState.activeMeeting != null, appState.isAdmin),
            ),
            body: content,
            bottomNavigationBar: const InstitutionalBottomNav(),
          );
        }
      },
    );
  }

  String _getTitle(int index, bool hasActiveMeeting, bool isAdmin) {
    switch (index) {
      case 0:
        return hasActiveMeeting ? 'Active Meeting Proceedings' : 'Convene New Meeting';
      case 1:
        return 'Past Meetings Archive';
      case 2:
        return 'Institutional Tasks Ledger';
      case 3:
        return 'Pending Tasks Register';
      case 4:
        return 'In Progress Tasks Register';
      case 5:
        return 'Completed Tasks Register';
      case 6:
        return 'Eliminated Tasks Register';
      case 7:
        return 'Institutional Members Directory';
      case 8:
        return 'Executive Progress Reports';
      case 9:
        return 'Administrative & Sync Settings';
      case 10:
        return 'Account Activities & Security Audit';
      default:
        return 'Meeting Tracker';
    }
  }
}
