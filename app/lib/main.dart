import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/institutional_theme.dart';
import 'state/app_state.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeetingTrackerApp());
}

class MeetingTrackerApp extends StatelessWidget {
  final bool initialAuthenticatedForTest;

  const MeetingTrackerApp({
    super.key,
    this.initialAuthenticatedForTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(initialAuthenticatedForTest: initialAuthenticatedForTest),
        ),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Institutional Meeting Tracker',
            debugShowCheckedModeBanner: false,
            theme: InstitutionalTheme.getTheme(appState.settings),
            home: appState.isAuthenticated ? const MainLayout() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
