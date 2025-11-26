import 'package:intl/intl.dart';

/// Data model representing a recent workout activity
/// 
/// Contains information about a completed workout including
/// name, type, details, and completion date.
class RecentActivity {
  /// Unique activity identifier
  final String id;
  
  /// Activity name (e.g., "Morning Run")
  final String name;
  
  /// Activity type: 'run', 'walk', 'workout', 'cycle'
  final String type;
  
  /// Activity details (e.g., "3.2 miles • 30 min")
  final String details;
  
  /// Activity completion date
  final DateTime date;

  RecentActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    required this.date,
  }) : assert(
         type == 'run' || type == 'walk' || type == 'workout' || type == 'cycle',
         'Activity type must be one of: run, walk, workout, cycle',
       ),
       assert(
         !date.isAfter(DateTime.now()),
         'Activity date must not be in the future',
       );

  /// Formats the date as "Today", "Yesterday", or "MMM d" based on recency
  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(activityDay).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  /// Creates a RecentActivity instance from JSON
  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      details: json['details'] as String,
      date: json['date'] is DateTime 
          ? json['date'] as DateTime
          : DateTime.parse(json['date'] as String),
    );
  }

  /// Converts this RecentActivity instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'details': details,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RecentActivity(id: $id, name: $name, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentActivity &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.details == details &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, details, date);
  }
}
