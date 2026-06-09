import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportigo/main.dart' as app;
import 'package:sportigo/screens/home_screen.dart';
import 'package:sportigo/screens/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Login and navigate to home screen',
        (WidgetTester tester) async {

      // Clear saved login/session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      app.main();

      await tester.pumpAndSettle();

      // Verify login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter username
      await tester.enterText(
        find.byKey(const Key('username_field')),
        'Devan',
      );

      // Enter password
      await tester.enterText(
        find.byKey(const Key('password_field')),
        '24681000',
      );

      await tester.pumpAndSettle();

      // Tap sign in button
      await tester.tap(
        find.byKey(const Key('signin_button')),
      );

      // Wait for login + navigation
      await tester.pumpAndSettle(
        const Duration(seconds: 5),
      );

      // Verify home screen loaded
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}