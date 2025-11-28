import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Logout - Property Tests', () {
    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    /// **Feature: dashboard-refactoring-merge, Property 13: Logout confirmation triggers signOut**
    /// **Validates: Requirements 8.2**
    ///
    /// Property: For any confirmed logout action, the authentication service
    /// signOut method should be called.
    testWidgets('Property 13: For any confirmed logout, signOut is called', (
      WidgetTester tester,
    ) async {
      // Create a mock auth repository that tracks signOut calls
      final mockAuthRepo = MockAuthRepositoryWithTracking();

      // Arrange: Build ProfileScreen with mock auth repository
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the logout text
      final logoutText = find.text('Logout');
      expect(logoutText, findsOneWidget, reason: 'Logout button should exist');

      // Ensure the widget is visible by scrolling
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();

      // Act: Tap the logout list item
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(
        find.text('Are you sure you want to logout?'),
        findsOneWidget,
        reason: 'Confirmation dialog should appear',
      );

      // Find and tap the "Logout" button in the dialog (red button)
      final confirmButtonFinder = find.widgetWithText(TextButton, 'Logout');
      expect(
        confirmButtonFinder,
        findsOneWidget,
        reason: 'Logout confirmation button should exist',
      );

      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // Wait for navigation to complete
      await tester.pumpAndSettle();

      // Assert: signOut should be called exactly once
      expect(
        mockAuthRepo.signOutCallCount,
        equals(1),
        reason: 'signOut should be called when logout is confirmed',
      );

      // Verify navigation to welcome screen occurred
      expect(
        find.text('Welcome Screen'),
        findsOneWidget,
        reason: 'Should navigate to welcome screen after logout',
      );
    });

    /// Property: For any cancelled logout action, the signOut method should
    /// NOT be called.
    testWidgets(
      'Property 13 (inverse): For any cancelled logout, signOut is NOT called',
      (WidgetTester tester) async {
        // Create a mock auth repository that tracks signOut calls
        final mockAuthRepo = MockAuthRepositoryWithTracking();

        // Arrange: Build ProfileScreen with mock auth repository
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
            child: MaterialApp(
              home: const ProfileScreen(),
              routes: {
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome Screen'))),
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the logout text
        final logoutText = find.text('Logout');
        expect(
          logoutText,
          findsOneWidget,
          reason: 'Logout button should exist',
        );

        // Ensure the widget is visible by scrolling
        await tester.ensureVisible(logoutText);
        await tester.pumpAndSettle();

        // Act: Tap the logout list item
        await tester.tap(logoutText, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(
          find.text('Are you sure you want to logout?'),
          findsOneWidget,
          reason: 'Confirmation dialog should appear',
        );

        // Find and tap the "Cancel" button in the dialog
        final cancelButtonFinder = find.widgetWithText(TextButton, 'Cancel');
        expect(
          cancelButtonFinder,
          findsOneWidget,
          reason: 'Cancel button should exist',
        );

        await tester.tap(cancelButtonFinder);
        await tester.pumpAndSettle();

        // Assert: signOut should NOT be called when cancelled
        expect(
          mockAuthRepo.signOutCallCount,
          equals(0),
          reason: 'signOut should NOT be called when logout is cancelled',
        );

        // Verify we're still on the profile screen
        expect(
          find.text('Logout'),
          findsOneWidget,
          reason: 'Should remain on profile screen after cancelling',
        );
      },
    );
  });
}

/// Mock AuthRepository that tracks signOut calls
class MockAuthRepositoryWithTracking implements IAuthRepository {
  int signOutCallCount = 0;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    // Track the signOut call
    signOutCallCount++;
    // Mock sign out - no actual operation needed
  }

  @override
  Future<User?> getCurrentUser() async {
    return User(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> authStateChanges() {
    // Mock auth state changes stream
    return Stream.value(
      User(
        id: 'test-user-123',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      ),
    );
  }
}
