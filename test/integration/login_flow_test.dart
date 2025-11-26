import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flowfit/secrets.dart';

/// Integration tests for login flows.
/// 
/// These tests verify:
/// - Login → Dashboard flow for users with complete profiles
/// - Login → Survey flow for users with incomplete profiles
/// - Session persistence across app restarts
/// - Invalid credentials handling
/// 
/// Requirements: 2.1, 5.2, 5.3, 5.4
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  });

  group('Login Flow Integration Tests', () {
    testWidgets(
      'INTEGRATION: Login with complete profile navigates to dashboard',
      (WidgetTester tester) async {
        // Note: This test requires a pre-existing user with completed profile
        // You'll need to create this user manually or in a setup script
        const testEmail = 'complete_user@flowfit.test';
        const testPassword = 'TestPassword123!';

        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should be on welcome screen
        // Navigate to login
        final loginLink = find.text('Log In');
        expect(loginLink, findsWidgets);
        await tester.tap(loginLink.first);
        await tester.pumpAndSettle();

        // Should be on login screen
        expect(find.text('Welcome Back!'), findsOneWidget);

        // Fill in login form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your password'),
          testPassword,
        );
        await tester.pumpAndSettle();

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton.last); // Last one is the button, not the link
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should navigate to dashboard
        expect(find.byType(Scaffold), findsWidgets);
        
        // Cleanup
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          // Ignore cleanup errors
        }
      },
      skip: true, // Skip by default as it requires manual user setup
    );

    testWidgets(
      'INTEGRATION: Login with incomplete profile navigates to survey',
      (WidgetTester tester) async {
        // Note: This test requires a pre-existing user WITHOUT completed profile
        const testEmail = 'incomplete_user@flowfit.test';
        const testPassword = 'TestPassword123!';

        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to login
        final loginLink = find.text('Log In');
        await tester.tap(loginLink.first);
        await tester.pumpAndSettle();

        // Fill in login form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your password'),
          testPassword,
        );
        await tester.pumpAndSettle();

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should navigate to survey intro
        expect(find.text('Quick Setup'), findsOneWidget);
        expect(find.text('(2 Minutes)'), findsOneWidget);
        
        // Cleanup
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          // Ignore cleanup errors
        }
      },
      skip: true, // Skip by default as it requires manual user setup
    );

    testWidgets(
      'INTEGRATION: Login with invalid credentials shows error',
      (WidgetTester tester) async {
        const testEmail = 'nonexistent@flowfit.test';
        const testPassword = 'WrongPassword123!';

        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to login
        final loginLink = find.text('Log In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink.first);
          await tester.pumpAndSettle();
        }

        // Fill in login form with invalid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your password'),
          testPassword,
        );
        await tester.pumpAndSettle();

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should show error message
        expect(find.byType(SnackBar), findsOneWidget);
        // Error message might vary, but should indicate invalid credentials
        expect(
          find.textContaining('Invalid'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'INTEGRATION: Session persistence - app restart with valid session',
      (WidgetTester tester) async {
        // This test simulates app restart with an existing session
        // Note: Requires a valid session to be present
        
        // First, create a session by logging in
        const testEmail = 'session_test@flowfit.test';
        const testPassword = 'TestPassword123!';

        // Initial app launch and login
        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to login
        final loginLink = find.text('Log In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink.first);
          await tester.pumpAndSettle();

          // Fill in login form
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Enter your email'),
            testEmail,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Enter your password'),
            testPassword,
          );
          await tester.pumpAndSettle();

          // Tap login button
          final loginButton = find.text('Log In');
          await tester.tap(loginButton.last);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // Now simulate app restart by creating a new app instance
        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should automatically navigate to dashboard or survey
        // (depending on profile completion status)
        // The key is that we should NOT be on the welcome screen
        expect(find.text('Find Your Flow'), findsNothing);
        
        // Cleanup
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          // Ignore cleanup errors
        }
      },
      skip: true, // Skip by default as it requires manual user setup
    );
  });

  group('Social Sign-In Shortcuts Integration Tests', () {
    testWidgets(
      'INTEGRATION: Google Sign-In button navigates to dashboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to login screen
        final loginLink = find.text('Log In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink.first);
          await tester.pumpAndSettle();
        }

        // Find and tap Google Sign-In button
        final googleButton = find.text('Sign in with Google');
        expect(googleButton, findsOneWidget);
        await tester.tap(googleButton);
        await tester.pumpAndSettle();

        // Should navigate directly to dashboard
        // Verify we're no longer on login screen
        expect(find.text('Welcome Back!'), findsNothing);
        expect(find.byType(Scaffold), findsWidgets);
      },
    );

    testWidgets(
      'INTEGRATION: Apple Sign-In button navigates to dashboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to login screen
        final loginLink = find.text('Log In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink.first);
          await tester.pumpAndSettle();
        }

        // Find and tap Apple Sign-In button
        final appleButton = find.text('Sign in with Apple');
        expect(appleButton, findsOneWidget);
        await tester.tap(appleButton);
        await tester.pumpAndSettle();

        // Should navigate directly to dashboard
        // Verify we're no longer on login screen
        expect(find.text('Welcome Back!'), findsNothing);
        expect(find.byType(Scaffold), findsWidgets);
      },
    );

    testWidgets(
      'INTEGRATION: Social sign-in does not create auth session',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FlowFitPhoneApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to login screen
        final loginLink = find.text('Log In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink.first);
          await tester.pumpAndSettle();
        }

        // Tap Google Sign-In button
        final googleButton = find.text('Sign in with Google');
        await tester.tap(googleButton);
        await tester.pumpAndSettle();

        // Verify no auth session was created
        final session = Supabase.instance.client.auth.currentSession;
        expect(session, isNull);
      },
    );
  });
}
