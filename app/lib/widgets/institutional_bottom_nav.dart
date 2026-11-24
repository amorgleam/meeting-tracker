import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';

class InstitutionalBottomNav extends StatelessWidget {
  const InstitutionalBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Map desktop indices to primary mobile tabs:
    // 0: Active Meeting
    // 1: Past Meetings
    // 2: Tasks Ledger
    // 7: Members
    // 8: Reports
    final currentIndex = _getMobileTabIndex(appState.selectedNavIndex);

    return Container(
      decoration: const BoxDecoration(
        color: InstitutionalTheme.primaryNavy,
        border: Border(
          top: BorderSide(color: InstitutionalTheme.goldDark, width: 1.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          final targetIndex = _mapTabToDesktopIndex(index);
          context.read<AppState>().setNavIndex(targetIndex);
        },
        backgroundColor: InstitutionalTheme.primaryNavy,
        selectedItemColor: InstitutionalTheme.goldAccent,
        unselectedItemColor: InstitutionalTheme.creamBackground.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            activeIcon: Icon(Icons.meeting_room),
            label: 'Meeting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_outlined),
            activeIcon: Icon(Icons.history_edu),
            label: 'Archive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_outlined),
            activeIcon: Icon(Icons.view_list),
            label: 'Docket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  int _getMobileTabIndex(int desktopIndex) {
    switch (desktopIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        return 2;
      case 7:
        return 3;
      case 8:
      case 9:
        return 4;
      default:
        return 0;
    }
  }

  int _mapTabToDesktopIndex(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 7;
      case 4:
        return 8;
      default:
        return 0;
    }
  }
}
