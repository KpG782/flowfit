/// Enum representing different types of workout activities
enum WorkoutType {
  running,
  walking,
  cycling,
  strength,
  yoga,
  other;

  /// Get a human-readable display name for the workout type
  String get displayName {
    switch (this) {
      case WorkoutType.running:
        return 'Running';
      case WorkoutType.walking:
        return 'Walking';
      case WorkoutType.cycling:
        return 'Cycling';
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.yoga:
        return 'Yoga';
      case WorkoutType.other:
        return 'Other';
    }
  }
}
