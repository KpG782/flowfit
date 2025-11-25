import 'workout_type.dart';
import 'heart_rate_point.dart';

/// Domain entity representing a workout session
class Workout {
  final String id;
  final String userId;
  final WorkoutType type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double? distance; // in kilometers
  final int? calories;
  final List<HeartRatePoint> heartRateData;
  final Map<String, dynamic>? metadata;

  const Workout({
    required this.id,
    required this.userId,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.distance,
    this.calories,
    required this.heartRateData,
    this.metadata,
  });

  Workout copyWith({
    String? id,
    String? userId,
    WorkoutType? type,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    double? distance,
    int? calories,
    List<HeartRatePoint>? heartRateData,
    Map<String, dynamic>? metadata,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      heartRateData: heartRateData ?? this.heartRateData,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Workout &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.duration == duration &&
        other.distance == distance &&
        other.calories == calories &&
        _listEquals(other.heartRateData, heartRateData) &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      type,
      startTime,
      endTime,
      duration,
      distance,
      calories,
      Object.hashAll(heartRateData),
      metadata,
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

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
