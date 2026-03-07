import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsify/presentation/providers/providers.dart';
import 'package:pulsify/screens/onboarding/survey_intro_screen.dart';
import 'package:pulsify/screens/onboarding/survey_basic_info_screen.dart';
import 'package:pulsify/screens/onboarding/survey_body_measurements_screen.dart';
import 'package:pulsify/screens/onboarding/survey_activity_goals_screen.dart';
import 'package:pulsify/screens/onboarding/survey_daily_targets_screen.dart';

/// Integration tests for survey back button navigation.
///
/// These tests verify:
/// - Back button works at each survey step
/// - Data is preserved when navigating back and forth
/// - No black screens appear during navigation
/// - Survey flow maintains proper navigation stack
///
/// Requirements: 1.1, 1.2, 1.4, 2.1, 2.2, 2.3
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Survey Back Button Navigation Tests', () {
    testWidgets('Back button navigates from Basic Info to Survey Intro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/survey_intro',
                          arguments: {
                            'userId': 'test-user-id',
                            'name': 'Test User',
                          },
                        );
                      },
                      child: const Text('Start Survey'),
                    ),
                  ),
                );
              },
            ),
            routes: {
              '/survey_intro': (context) => const SurveyIntroScreen(),
              '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to start survey
      await tester.tap(find.text('Start Survey'));
      await tester.pumpAndSettle();

      // Should be on survey intro
      expect(find.text('Quick Setup'), findsOneWidget);

      // Tap "LET'S PERSONALIZE" to go to basic info
      await tester.tap(find.text('LET\'S PERSONALIZE'));
      await tester.pumpAndSettle();

      // Should be on basic info screen
      expect(find.text('Tell us about yourself'), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should be back on survey intro
      expect(find.text('Quick Setup'), findsOneWidget);
      expect(find.text('(2 Minutes)'), findsOneWidget);
    });

    testWidgets(
      'Data is preserved when navigating back from Body Measurements',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/survey_basic_info',
                            arguments: {
                              'userId': 'test-user-id',
                              'name': 'Test User',
                            },
                          );
                        },
                        child: const Text('Start Survey'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/survey_basic_info': (context) =>
                    const SurveyBasicInfoScreen(),
                '/survey_body_measurements': (context) =>
                    const SurveyBodyMeasurementsScreen(),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start survey
        await tester.tap(find.text('Start Survey'));
        await tester.pumpAndSettle();

        // Fill in basic info
        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();

        // Enter age
        final ageField = find.byType(TextFormField).first;
        await tester.enterText(ageField, '30');
        await tester.pumpAndSettle();

        // Tap Continue
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should be on body measurements
        expect(find.text('Body Measurements'), findsOneWidget);

        // Tap back button
        final backButton = find.byIcon(Icons.arrow_back);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should be back on basic info
        expect(find.text('Tell us about yourself'), findsOneWidget);

        // Verify data is preserved
        final surveyState = container.read(surveyNotifierProvider);
        expect(surveyState.surveyData['age'], 30);
        expect(surveyState.surveyData['gender'], 'Male');
      },
    );

    testWidgets('Back button works through all survey steps', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/survey_intro',
                          arguments: {
                            'userId': 'test-user-id',
                            'name': 'Test User',
                          },
                        );
                      },
                      child: const Text('Start Survey'),
                    ),
                  ),
                );
              },
            ),
            routes: {
              '/survey_intro': (context) => const SurveyIntroScreen(),
              '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
              '/survey_body_measurements': (context) =>
                  const SurveyBodyMeasurementsScreen(),
              '/survey_activity_goals': (context) =>
                  const SurveyActivityGoalsScreen(),
              '/survey_daily_targets': (context) =>
                  const SurveyDailyTargetsScreen(),
              '/dashboard': (context) => Scaffold(
                appBar: AppBar(title: const Text('Dashboard')),
                body: const Center(child: Text('Dashboard')),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start survey
      await tester.tap(find.text('Start Survey'));
      await tester.pumpAndSettle();

      // Step 0: Survey Intro
      expect(find.text('Quick Setup'), findsOneWidget);
      await tester.tap(find.text('LET\'S PERSONALIZE'));
      await tester.pumpAndSettle();

      // Step 1: Basic Info
      expect(find.text('Tell us about yourself'), findsOneWidget);
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      final ageField = find.byType(TextFormField).first;
      await tester.enterText(ageField, '30');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Body Measurements
      expect(find.text('Body Measurements'), findsOneWidget);
      final weightField = find.widgetWithText(
        TextFormField,
        'Enter weight in kg',
      );
      await tester.enterText(weightField, '75');
      await tester.pumpAndSettle();
      final heightField = find.widgetWithText(
        TextFormField,
        'Enter height in cm',
      );
      await tester.enterText(heightField, '175');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Activity Goals
      expect(find.text('Activity & Goals'), findsOneWidget);
      await tester.tap(find.text('Moderately Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lose Weight'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Daily Targets
      expect(find.text('Your Daily Targets'), findsOneWidget);

      // Now navigate back through all steps
      // Back from Daily Targets to Activity Goals
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Activity & Goals'), findsOneWidget);

      // Back from Activity Goals to Body Measurements
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Body Measurements'), findsOneWidget);

      // Back from Body Measurements to Basic Info
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Tell us about yourself'), findsOneWidget);

      // Back from Basic Info to Survey Intro
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Quick Setup'), findsOneWidget);

      // Verify no black screens appeared (all expected screens were found)
      // Verify data is still preserved
      final surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 30);
      expect(surveyState.surveyData['gender'], 'Male');
      expect(surveyState.surveyData['weight'], 75.0);
      expect(surveyState.surveyData['height'], 175.0);
    });

    testWidgets('Forward and backward navigation preserves all data', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/survey_basic_info',
                          arguments: {
                            'userId': 'test-user-id',
                            'name': 'Test User',
                          },
                        );
                      },
                      child: const Text('Start Survey'),
                    ),
                  ),
                );
              },
            ),
            routes: {
              '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
              '/survey_body_measurements': (context) =>
                  const SurveyBodyMeasurementsScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start survey
      await tester.tap(find.text('Start Survey'));
      await tester.pumpAndSettle();

      // Fill in basic info
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();
      final ageField = find.byType(TextFormField).first;
      await tester.enterText(ageField, '25');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Fill in body measurements
      final weightField = find.widgetWithText(
        TextFormField,
        'Enter weight in kg',
      );
      await tester.enterText(weightField, '60');
      await tester.pumpAndSettle();
      final heightField = find.widgetWithText(
        TextFormField,
        'Enter height in cm',
      );
      await tester.enterText(heightField, '165');
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're on basic info and data is preserved
      expect(find.text('Tell us about yourself'), findsOneWidget);
      var surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 25);
      expect(surveyState.surveyData['gender'], 'Female');
      expect(surveyState.surveyData['weight'], 60.0);
      expect(surveyState.surveyData['height'], 165.0);

      // Go forward again
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify we're on body measurements and data is still there
      expect(find.text('Body Measurements'), findsOneWidget);
      surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 25);
      expect(surveyState.surveyData['gender'], 'Female');
      expect(surveyState.surveyData['weight'], 60.0);
      expect(surveyState.surveyData['height'], 165.0);
    });

    testWidgets('No black screen appears when using back button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/survey_basic_info',
                          arguments: {
                            'userId': 'test-user-id',
                            'name': 'Test User',
                          },
                        );
                      },
                      child: const Text('Start Survey'),
                    ),
                  ),
                );
              },
            ),
            routes: {
              '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
              '/survey_body_measurements': (context) =>
                  const SurveyBodyMeasurementsScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start survey
      await tester.tap(find.text('Start Survey'));
      await tester.pumpAndSettle();

      // Fill in basic info
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      final ageField = find.byType(TextFormField).first;
      await tester.enterText(ageField, '30');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify we're on body measurements (not a black screen)
      expect(find.text('Body Measurements'), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're on basic info (not a black screen)
      expect(find.text('Tell us about yourself'), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);

      // Verify no error widgets or empty containers
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
