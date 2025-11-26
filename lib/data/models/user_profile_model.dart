import '../../domain/entities/user_profile.dart';

/// Data model for UserProfile that maps to/from Supabase Database.
/// Handles JSON serialization for database operations.
class UserProfileModel {
  final String userId;
  final String fullName;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String activityLevel;
  final List<String> goals;
  final int dailyCalorieTarget;
  final bool surveyCompleted;
  final String createdAt;
  final String updatedAt;

  const UserProfileModel({
    required this.userId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.goals,
    required this.dailyCalorieTarget,
    required this.surveyCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserProfileModel from JSON data received from Supabase.
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      activityLevel: json['activity_level'] as String,
      goals: (json['goals'] as List<dynamic>).cast<String>(),
      dailyCalorieTarget: json['daily_calorie_target'] as int,
      surveyCompleted: json['survey_completed'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  /// Converts this UserProfileModel to JSON for sending to Supabase.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'activity_level': activityLevel,
      'goals': goals,
      'daily_calorie_target': dailyCalorieTarget,
      'survey_completed': surveyCompleted,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Converts this data model to a domain entity.
  UserProfile toDomain() {
    return UserProfile(
      userId: userId,
      fullName: fullName,
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      activityLevel: activityLevel,
      goals: goals,
      dailyCalorieTarget: dailyCalorieTarget,
      surveyCompleted: surveyCompleted,
    );
  }

  /// Creates a UserProfileModel from a domain entity.
  /// Uses current timestamp for createdAt and updatedAt if not provided.
  factory UserProfileModel.fromDomain(UserProfile profile) {
    final now = DateTime.now().toIso8601String();
    return UserProfileModel(
      userId: profile.userId,
      fullName: profile.fullName,
      age: profile.age,
      gender: profile.gender,
      weight: profile.weight,
      height: profile.height,
      activityLevel: profile.activityLevel,
      goals: profile.goals,
      dailyCalorieTarget: profile.dailyCalorieTarget,
      surveyCompleted: profile.surveyCompleted,
      createdAt: now,
      updatedAt: now,
    );
  }
}
