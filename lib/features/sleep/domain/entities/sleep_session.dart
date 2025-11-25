import 'sleep_quality.dart';
import 'sleep_stage.dart';

/// Domain entity representing a sleep session
class SleepSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final SleepQuality quality;
  final List<SleepStage> stages;
  final int interruptions;

  const SleepSession({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.quality,
    required this.stages,
    required this.interruptions,
  });

  /// Calculate total time in deep sleep
  Duration get deepSleepDuration {
    return stages
        .where((stage) => stage.type == SleepStageType.deep)
        .fold(Duration.zero, (total, stage) => total + stage.duration);
  }

  /// Calculate total time in REM sleep
  Duration get remSleepDuration {
    return stages
        .where((stage) => stage.type == SleepStageType.rem)
        .fold(Duration.zero, (total, stage) => total + stage.duration);
  }

  /// Calculate total time in light sleep
  Duration get lightSleepDuration {
    return stages
        .where((stage) => stage.type == SleepStageType.light)
        .fold(Duration.zero, (total, stage) => total + stage.duration);
  }

  /// Calculate total time awake
  Duration get awakeDuration {
    return stages
        .where((stage) => stage.type == SleepStageType.awake)
        .fold(Duration.zero, (total, stage) => total + stage.duration);
  }

  SleepSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    SleepQuality? quality,
    List<SleepStage>? stages,
    int? interruptions,
  }) {
    return SleepSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      stages: stages ?? this.stages,
      interruptions: interruptions ?? this.interruptions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepSession &&
        other.id == id &&
        other.userId == userId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.duration == duration &&
        other.quality == quality &&
        _listEquals(other.stages, stages) &&
        other.interruptions == interruptions;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      startTime,
      endTime,
      duration,
      quality,
      Object.hashAll(stages),
      interruptions,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SleepSession(id: $id, duration: ${duration.inHours}h ${duration.inMinutes % 60}m, quality: ${quality.displayName})';
  }
}
