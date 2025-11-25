import 'streak_type.dart';

/// Domain entity representing a user's streak data
class Streak {
  final StreakType type;
  final int currentCount;
  final int longestCount;
  final DateTime? lastActivityDate;
  final List<DateTime> activityDates;

  const Streak({
    required this.type,
    required this.currentCount,
    required this.longestCount,
    this.lastActivityDate,
    required this.activityDates,
  });

  /// Check if the streak is currently active (activity within last 24 hours)
  bool get isActive {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastActivityDate!);
    return difference.inHours < 24;
  }

  /// Check if the streak is broken (no activity for more than 24 hours)
  bool get isBroken {
    if (lastActivityDate == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastActivityDate!);
    return difference.inHours >= 48; // Grace period of 48 hours
  }

  /// Get milestone achievements (e.g., 7 days, 30 days, 100 days)
  List<int> get achievedMilestones {
    final milestones = [7, 14, 30, 50, 100, 365];
    return milestones.where((m) => longestCount >= m).toList();
  }

  /// Get the next milestone to achieve
  int? get nextMilestone {
    final milestones = [7, 14, 30, 50, 100, 365];
    for (final milestone in milestones) {
      if (currentCount < milestone) {
        return milestone;
      }
    }
    return null; // All milestones achieved
  }

  /// Calculate days until next milestone
  int? get daysToNextMilestone {
    final next = nextMilestone;
    if (next == null) return null;
    return next - currentCount;
  }

  Streak copyWith({
    StreakType? type,
    int? currentCount,
    int? longestCount,
    DateTime? lastActivityDate,
    List<DateTime>? activityDates,
  }) {
    return Streak(
      type: type ?? this.type,
      currentCount: currentCount ?? this.currentCount,
      longestCount: longestCount ?? this.longestCount,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      activityDates: activityDates ?? this.activityDates,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Streak &&
        other.type == type &&
        other.currentCount == currentCount &&
        other.longestCount == longestCount &&
        other.lastActivityDate == lastActivityDate &&
        _listEquals(other.activityDates, activityDates);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      currentCount,
      longestCount,
      lastActivityDate,
      Object.hashAll(activityDates),
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
    return 'Streak(type: ${type.displayName}, current: $currentCount, longest: $longestCount)';
  }
}
