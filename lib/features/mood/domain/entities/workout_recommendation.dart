import '../../../../core/domain/entities/workout_type.dart';

/// Domain entity representing a workout recommendation based on mood
class WorkoutRecommendation {
  final WorkoutType type;
  final String title;
  final String description;
  final int intensity; // 1-5 scale
  final Duration suggestedDuration;
  final String reason;

  const WorkoutRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.intensity,
    required this.suggestedDuration,
    required this.reason,
  });

  WorkoutRecommendation copyWith({
    WorkoutType? type,
    String? title,
    String? description,
    int? intensity,
    Duration? suggestedDuration,
    String? reason,
  }) {
    return WorkoutRecommendation(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      intensity: intensity ?? this.intensity,
      suggestedDuration: suggestedDuration ?? this.suggestedDuration,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutRecommendation &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.intensity == intensity &&
        other.suggestedDuration == suggestedDuration &&
        other.reason == reason;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      title,
      description,
      intensity,
      suggestedDuration,
      reason,
    );
  }

  @override
  String toString() {
    return 'WorkoutRecommendation(type: ${type.displayName}, intensity: $intensity, duration: ${suggestedDuration.inMinutes}min)';
  }
}
