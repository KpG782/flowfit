/// Domain entity representing a user's profile information.
/// Immutable for use with Riverpod state management.
class UserProfile {
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

  const UserProfile({
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
  });

  /// Creates a copy of this profile with the given fields replaced
  UserProfile copyWith({
    String? userId,
    String? fullName,
    int? age,
    String? gender,
    double? weight,
    double? height,
    String? activityLevel,
    List<String>? goals,
    int? dailyCalorieTarget,
    bool? surveyCompleted,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      activityLevel: activityLevel ?? this.activityLevel,
      goals: goals ?? this.goals,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          fullName == other.fullName &&
          age == other.age &&
          gender == other.gender &&
          weight == other.weight &&
          height == other.height &&
          activityLevel == other.activityLevel &&
          _listEquals(goals, other.goals) &&
          dailyCalorieTarget == other.dailyCalorieTarget &&
          surveyCompleted == other.surveyCompleted;

  @override
  int get hashCode =>
      userId.hashCode ^
      fullName.hashCode ^
      age.hashCode ^
      gender.hashCode ^
      weight.hashCode ^
      height.hashCode ^
      activityLevel.hashCode ^
      goals.hashCode ^
      dailyCalorieTarget.hashCode ^
      surveyCompleted.hashCode;

  @override
  String toString() {
    return 'UserProfile{userId: $userId, fullName: $fullName, age: $age, gender: $gender, weight: $weight, height: $height, activityLevel: $activityLevel, goals: $goals, dailyCalorieTarget: $dailyCalorieTarget, surveyCompleted: $surveyCompleted}';
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
