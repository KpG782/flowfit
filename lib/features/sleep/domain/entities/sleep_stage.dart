/// Enum representing different sleep stages
enum SleepStageType {
  awake,
  light,
  deep,
  rem;

  /// Get a human-readable display name for the sleep stage
  String get displayName {
    switch (this) {
      case SleepStageType.awake:
        return 'Awake';
      case SleepStageType.light:
        return 'Light Sleep';
      case SleepStageType.deep:
        return 'Deep Sleep';
      case SleepStageType.rem:
        return 'REM Sleep';
    }
  }
}

/// Domain entity representing a sleep stage period
class SleepStage {
  final SleepStageType type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  const SleepStage({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  SleepStage copyWith({
    SleepStageType? type,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
  }) {
    return SleepStage(
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepStage &&
        other.type == type &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return Object.hash(type, startTime, endTime, duration);
  }

  @override
  String toString() {
    return 'SleepStage(type: ${type.displayName}, duration: ${duration.inMinutes}min)';
  }
}
