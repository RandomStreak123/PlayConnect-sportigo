import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:sportigo/main.dart' as app;
import 'package:sportigo/screens/login_screen.dart';
import 'package:sportigo/screens/profile_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Profile screen loads correctly',
        (WidgetTester tester) async {

      app.main();

      await tester.pumpAndSettle();

      // Log in if we are on the login screen
      if (find.byType(LoginScreen).evaluate().isNotEmpty) {
        await tester.enterText(
          find.byKey(const Key('username_field')),
          'Devan',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          '24681000',
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('signin_button')),
        );
        await tester.pumpAndSettle(
          const Duration(seconds: 5),
        );
      }

      // Navigate to profile screen
      final profileButton = find.byIcon(Icons.person_rounded);

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
      final cricketChip = find.text('Cricket').first;
      await tester.ensureVisible(cricketChip);
      await tester.pumpAndSettle();
      await tester.tap(cricketChip);

      await tester.pumpAndSettle();

      // Verify activity section exists
      expect(
        find.text('Activity Log'),
        findsOneWidget,
      );
    },
  );
}