/// Enum representing sleep quality ratings
enum SleepQuality {
  poor,
  fair,
  good,
  excellent;

  /// Get a human-readable display name for the sleep quality
  String get displayName {
    switch (this) {
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.excellent:
        return 'Excellent';
    }
  }

  /// Get a numeric score for the quality (1-4)
  int get score {
    switch (this) {
      case SleepQuality.poor:
        return 1;
      case SleepQuality.fair:
        return 2;
      case SleepQuality.good:
        return 3;
      case SleepQuality.excellent:
        return 4;
    }
  }
}
