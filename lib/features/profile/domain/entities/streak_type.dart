/// Enum representing different types of streaks
enum StreakType {
  workout,
  nutrition,
  appUsage;

  /// Get a human-readable display name for the streak type
  String get displayName {
    switch (this) {
      case StreakType.workout:
        return 'Workout Streak';
      case StreakType.nutrition:
        return 'Nutrition Logging Streak';
      case StreakType.appUsage:
        return 'App Usage Streak';
    }
  }

  /// Get a short description of what counts for this streak
  String get description {
    switch (this) {
      case StreakType.workout:
        return 'Complete at least one workout per day';
      case StreakType.nutrition:
        return 'Log at least one meal per day';
      case StreakType.appUsage:
        return 'Open the app at least once per day';
    }
  }

  /// Get an emoji representation of the streak type
  String get emoji {
    switch (this) {
      case StreakType.workout:
        return '💪';
      case StreakType.nutrition:
        return '🍎';
      case StreakType.appUsage:
        return '📱';
    }
  }
}
