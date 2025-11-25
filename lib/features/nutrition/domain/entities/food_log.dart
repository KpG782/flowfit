import 'macros.dart';
import 'meal_type.dart';

/// Domain entity representing a logged food entry
class FoodLog {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String foodName;
  final int calories;
  final Macros macros;
  final MealType mealType;

  const FoodLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.foodName,
    required this.calories,
    required this.macros,
    required this.mealType,
  });

  FoodLog copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? foodName,
    int? calories,
    Macros? macros,
    MealType? mealType,
  }) {
    return FoodLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      mealType: mealType ?? this.mealType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FoodLog &&
        other.id == id &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.foodName == foodName &&
        other.calories == calories &&
        other.macros == macros &&
        other.mealType == mealType;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      timestamp,
      foodName,
      calories,
      macros,
      mealType,
    );
  }

  @override
  String toString() {
    return 'FoodLog(id: $id, foodName: $foodName, calories: $calories, mealType: ${mealType.displayName})';
  }
}
