import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/providers/dashboard_providers.dart';
import 'package:flowfit/models/daily_stats.dart';
import 'package:flowfit/models/recent_activity.dart';

void main() {
  group('Dashboard Providers', () {
    test('dailyStatsProvider returns DailyStats', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stats = await container.read(dailyStatsProvider.future);

      expect(stats, isA<DailyStats>());
      expect(stats.steps, greaterThanOrEqualTo(0));
      expect(stats.stepsGoal, greaterThan(0));
      expect(stats.calories, greaterThanOrEqualTo(0));
      expect(stats.activeMinutes, greaterThanOrEqualTo(0));
    });

    test('recentActivitiesProvider returns list of activities', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final activities = await container.read(recentActivitiesProvider.future);

      expect(activities, isA<List<RecentActivity>>());
      expect(activities, isNotEmpty);
      
      for (final activity in activities) {
        expect(activity.id, isNotEmpty);
        expect(activity.name, isNotEmpty);
        expect(['run', 'walk', 'workout', 'cycle'], contains(activity.type));
      }
    });

    test('selectedNavIndexProvider starts at 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final index = container.read(selectedNavIndexProvider);

      expect(index, 0);
    });

    test('selectedNavIndexProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedNavIndexProvider.notifier).state = 2;
      final index = container.read(selectedNavIndexProvider);

      expect(index, 2);
    });

    test('unreadNotificationsProvider starts at 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = container.read(unreadNotificationsProvider);

      expect(count, 0);
    });

    test('unreadNotificationsProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(unreadNotificationsProvider.notifier).state = 5;
      final count = container.read(unreadNotificationsProvider);

      expect(count, 5);
    });

    test('dailyStatsProvider can be invalidated and refetched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First fetch
      final stats1 = await container.read(dailyStatsProvider.future);
      expect(stats1, isA<DailyStats>());

      // Invalidate
      container.invalidate(dailyStatsProvider);

      // Second fetch
      final stats2 = await container.read(dailyStatsProvider.future);
      expect(stats2, isA<DailyStats>());
    });

    test('recentActivitiesProvider can be invalidated and refetched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First fetch
      final activities1 = await container.read(recentActivitiesProvider.future);
      expect(activities1, isA<List<RecentActivity>>());

      // Invalidate
      container.invalidate(recentActivitiesProvider);

      // Second fetch
      final activities2 = await container.read(recentActivitiesProvider.future);
      expect(activities2, isA<List<RecentActivity>>());
    });
  });
}
