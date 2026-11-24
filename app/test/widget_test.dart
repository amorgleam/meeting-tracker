import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_tracker/main.dart';

void main() {
  testWidgets('Meeting Tracker App builds and displays main layout in desktop mode', (WidgetTester tester) async {
    // Set desktop window size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MeetingTrackerApp());
    await tester.pumpAndSettle();

    // Verify Institutional Branding & Navigation
    expect(find.text('MEETING TRACKER'), findsOneWidget);
    expect(find.text('Office of the Secretariat'), findsOneWidget);
    expect(find.text('ACTIVE SESSION'), findsWidgets);
    expect(find.text('ADD MAIN TASK'), findsOneWidget);
  });

  testWidgets('Meeting Tracker App renders mobile layout on narrow screens', (WidgetTester tester) async {
    // Set mobile phone size
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MeetingTrackerApp());
    await tester.pumpAndSettle();

    // Verify Mobile Bottom Navigation items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Docket'), findsOneWidget);
  });
}
