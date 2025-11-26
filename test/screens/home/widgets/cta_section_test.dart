import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/screens/home/widgets/cta_section.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('CTASection', () {
    late GoRouter router;
    String? lastNavigatedRoute;

    setUp(() {
      lastNavigatedRoute = null;
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: CTASection(),
            ),
          ),
          GoRoute(
            path: '/active',
            builder: (context, state) {
              lastNavigatedRoute = '/active';
              final type = state.uri.queryParameters['type'];
              if (type != null) {
                lastNavigatedRoute = '/active?type=$type';
              }
              return const Scaffold(
                body: Text('Active Screen'),
              );
            },
          ),
        ],
      );
    });

    testWidgets('displays section header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Ready to move?'), findsOneWidget);
    });

    testWidgets('displays all three buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Start a Workout'), findsOneWidget);
      expect(find.text('Log a Run'), findsOneWidget);
      expect(find.text('Record a Walk'), findsOneWidget);
    });

    testWidgets('Start a Workout button is ElevatedButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      final startWorkoutButton = find.ancestor(
        of: find.text('Start a Workout'),
        matching: find.byType(ElevatedButton),
      );
      expect(startWorkoutButton, findsOneWidget);
    });

    testWidgets('Log a Run button is OutlinedButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      final logRunButton = find.ancestor(
        of: find.text('Log a Run'),
        matching: find.byType(OutlinedButton),
      );
      expect(logRunButton, findsOneWidget);
    });

    testWidgets('Record a Walk button is OutlinedButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      final recordWalkButton = find.ancestor(
        of: find.text('Record a Walk'),
        matching: find.byType(OutlinedButton),
      );
      expect(recordWalkButton, findsOneWidget);
    });

    testWidgets('all buttons have 56dp height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Find all SizedBox widgets that wrap the buttons
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(CTASection),
          matching: find.byType(SizedBox),
        ),
      );

      // Filter for the button containers (height: 56)
      final buttonContainers = sizedBoxes.where((box) => box.height == 56);
      expect(buttonContainers.length, 3);
    });

    testWidgets('Start a Workout navigates to /active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('Start a Workout'));
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, '/active');
    });

    testWidgets('Log a Run navigates to /active?type=run', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('Log a Run'));
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, '/active?type=run');
    });

    testWidgets('Record a Walk navigates to /active?type=walk', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('Record a Walk'));
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, '/active?type=walk');
    });

    testWidgets('uses theme colors correctly', (WidgetTester tester) async {
      const testPrimaryColor = Colors.blue;
      const testOnPrimaryColor = Colors.white;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: testPrimaryColor,
              onPrimary: testOnPrimaryColor,
            ),
          ),
          home: const Scaffold(
            body: CTASection(),
          ),
        ),
      );

      // Find the ElevatedButton
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Start a Workout'),
          matching: find.byType(ElevatedButton),
        ),
      );

      final buttonStyle = elevatedButton.style;
      expect(
        buttonStyle?.backgroundColor?.resolve({}),
        testPrimaryColor,
      );
      expect(
        buttonStyle?.foregroundColor?.resolve({}),
        testOnPrimaryColor,
      );
    });

    testWidgets('buttons have 16px border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Check ElevatedButton border radius
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Start a Workout'),
          matching: find.byType(ElevatedButton),
        ),
      );
      final elevatedShape = elevatedButton.style?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(elevatedShape.borderRadius, BorderRadius.circular(16));

      // Check OutlinedButton border radius
      final outlinedButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Log a Run'),
          matching: find.byType(OutlinedButton),
        ),
      );
      final outlinedShape = outlinedButton.style?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(outlinedShape.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('section header uses titleLarge with bold weight', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 22),
            ),
          ),
          home: const Scaffold(
            body: CTASection(),
          ),
        ),
      );

      final headerText = tester.widget<Text>(find.text('Ready to move?'));
      expect(headerText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('buttons are full width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Find all SizedBox widgets that wrap the buttons
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(CTASection),
          matching: find.byType(SizedBox),
        ),
      );

      // Filter for the button containers (width: double.infinity, height: 56)
      final buttonContainers = sizedBoxes.where(
        (box) => box.width == double.infinity && box.height == 56,
      );
      expect(buttonContainers.length, 3);
    });
  });
}
