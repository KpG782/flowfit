import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/models/daily_stats.dart';

void main() {
  group('DailyStats', () {
    test('creates instance with valid data', () {
      final stats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      expect(stats.steps, 5000);
      expect(stats.stepsGoal, 10000);
      expect(stats.calories, 300);
      expect(stats.activeMinutes, 30);
    });

    test('calculates stepsProgress correctly', () {
      final stats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      expect(stats.stepsProgress, 0.5);
    });

    test('stepsProgress handles goal completion', () {
      final stats = DailyStats(
        steps: 10000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      expect(stats.stepsProgress, 1.0);
    });

    test('stepsProgress handles exceeding goal', () {
      final stats = DailyStats(
        steps: 15000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      expect(stats.stepsProgress, 1.5);
    });

    test('fromJson creates valid instance', () {
      final json = {
        'steps': 5000,
        'stepsGoal': 10000,
        'calories': 300,
        'activeMinutes': 30,
      };

      final stats = DailyStats.fromJson(json);

      expect(stats.steps, 5000);
      expect(stats.stepsGoal, 10000);
      expect(stats.calories, 300);
      expect(stats.activeMinutes, 30);
    });

    test('fromJson handles missing values with defaults', () {
      final json = <String, dynamic>{};

      final stats = DailyStats.fromJson(json);

      expect(stats.steps, 0);
      expect(stats.stepsGoal, 10000);
      expect(stats.calories, 0);
      expect(stats.activeMinutes, 0);
    });

    test('toJson creates valid map', () {
      final stats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      final json = stats.toJson();

      expect(json['steps'], 5000);
      expect(json['stepsGoal'], 10000);
      expect(json['calories'], 300);
      expect(json['activeMinutes'], 30);
    });

    test('equality works correctly', () {
      final stats1 = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      final stats2 = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      expect(stats1, stats2);
    });

    test('hashCode works correctly', () {
      final stats1 = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      final stats2 = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      expect(stats1.hashCode, stats2.hashCode);
    });

    test('asserts on negative steps', () {
      expect(
        () => DailyStats(
          steps: -1,
          stepsGoal: 10000,
          calories: 300,
          activeMinutes: 30,
        ),
        throwsAssertionError,
      );
    });

    test('asserts on zero or negative stepsGoal', () {
      expect(
        () => DailyStats(
          steps: 5000,
          stepsGoal: 0,
          calories: 300,
          activeMinutes: 30,
        ),
        throwsAssertionError,
      );
    });

    test('asserts on negative calories', () {
      expect(
        () => DailyStats(
          steps: 5000,
          stepsGoal: 10000,
          calories: -1,
          activeMinutes: 30,
        ),
        throwsAssertionError,
      );
    });

    test('asserts on negative activeMinutes', () {
      expect(
        () => DailyStats(
          steps: 5000,
          stepsGoal: 10000,
          calories: 300,
          activeMinutes: -1,
        ),
        throwsAssertionError,
      );
    });
  });
}
