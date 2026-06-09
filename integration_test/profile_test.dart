import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:sportigo/main.dart' as app;
import 'package:sportigo/screens/profile_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Profile screen loads correctly',
        (WidgetTester tester) async {

      app.main();

      await tester.pumpAndSettle(
        const Duration(seconds: 5),
      );

      // Navigate to profile screen
      // Change this finder according to your app

      final profileButton =
      find.byIcon(Icons.person_rounded);

      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Verify profile screen
      expect(
        find.byType(ProfileScreen),
        findsOneWidget,
      );

      // Verify title
      expect(
        find.text('Player Profile'),
        findsOneWidget,
      );

      // Verify level section
      expect(
        find.textContaining('Level'),
        findsWidgets,
      );

      // Verify sports section
      expect(
        find.text('Football'),
        findsWidgets,
      );

      expect(
        find.text('Cricket'),
        findsWidgets,
      );

      // Tap sport chip
      await tester.tap(find.text('Cricket').first);

      await tester.pumpAndSettle();

      // Verify activity section exists
      expect(
        find.text('Activity Log'),
        findsOneWidget,
      );
    },
  );
}