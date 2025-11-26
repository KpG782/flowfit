import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_stats.dart';
import '../models/recent_activity.dart';

/// Provider for fetching daily fitness statistics
/// 
/// Returns DailyStats containing steps, calories, and active minutes.
/// States: loading, data(DailyStats), error
/// 
/// Refresh by calling: ref.invalidate(dailyStatsProvider)
final dailyStatsProvider = FutureProvider<DailyStats>((ref) async {
  // TODO: Replace with actual data source (Supabase, SQLite, etc.)
  // Simulating async data fetch
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Mock data for development
  return DailyStats(
    steps: 6504,
    stepsGoal: 10000,
    calories: 387,
    activeMinutes: 45,
  );
});

/// Provider for fetching recent workout activities
/// 
/// Returns a list of RecentActivity objects sorted by most recent first.
/// States: loading, data(List<RecentActivity>), error
/// 
/// Refresh by calling: ref.invalidate(recentActivitiesProvider)
final recentActivitiesProvider = FutureProvider<List<RecentActivity>>((ref) async {
  // TODO: Replace with actual data source (Supabase, SQLite, etc.)
  // Simulating async data fetch
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Mock data for development
  final now = DateTime.now();
  return [
    RecentActivity(
      id: '1',
      name: 'Morning Run',
      type: 'run',
      details: '3.2 miles • 30 min',
      date: now,
    ),
    RecentActivity(
      id: '2',
      name: 'Evening Walk',
      type: 'walk',
      details: '1.5 miles • 20 min',
      date: now.subtract(const Duration(days: 1)),
    ),
    RecentActivity(
      id: '3',
      name: 'Gym Workout',
      type: 'workout',
      details: '45 min • Upper body',
      date: now.subtract(const Duration(days: 2)),
    ),
    RecentActivity(
      id: '4',
      name: 'Bike Ride',
      type: 'cycle',
      details: '10 miles • 45 min',
      date: now.subtract(const Duration(days: 3)),
    ),
  ];
});

/// Provider for managing the selected bottom navigation index
/// 
/// Initial value: 0 (Home)
/// Range: 0-4 (5 navigation items: Home, Health, Track, Progress, Profile)
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for managing unread notification count
/// 
/// Initial value: 0
/// Display logic: Shows "9+" when count > 9
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);
