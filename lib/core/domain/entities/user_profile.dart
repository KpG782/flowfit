/// Core domain entity representing a user's profile information
class UserProfile {
  final String id;
  final String username;
  final String? profilePhotoUrl;
  final String? email;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? location;
  final double? currentWeight;
  final double? goalWeight;

  const UserProfile({
    required this.id,
    required this.username,
    this.profilePhotoUrl,
    this.email,
    this.dateOfBirth,
    this.sex,
    this.location,
    this.currentWeight,
    this.goalWeight,
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? profilePhotoUrl,
    String? email,
    DateTime? dateOfBirth,
    String? sex,
    String? location,
    double? currentWeight,
    double? goalWeight,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      location: location ?? this.location,
      currentWeight: currentWeight ?? this.currentWeight,
      goalWeight: goalWeight ?? this.goalWeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.username == username &&
        other.profilePhotoUrl == profilePhotoUrl &&
        other.email == email &&
        other.dateOfBirth == dateOfBirth &&
        other.sex == sex &&
        other.location == location &&
        other.currentWeight == currentWeight &&
        other.goalWeight == goalWeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      profilePhotoUrl,
      email,
      dateOfBirth,
      sex,
      location,
      currentWeight,
      goalWeight,
    );
  }
}
