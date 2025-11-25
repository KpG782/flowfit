import 'mood_type.dart';

/// Domain entity representing a mood log entry
class MoodEntry {
  final String id;
  final String userId;
  final DateTime timestamp;
  final MoodType mood;
  final String? notes;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.mood,
    this.notes,
  });

  MoodEntry copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    MoodType? mood,
    String? notes,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodEntry &&
        other.id == id &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.mood == mood &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, timestamp, mood, notes);
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, mood: ${mood.displayName}, timestamp: $timestamp)';
  }
}
