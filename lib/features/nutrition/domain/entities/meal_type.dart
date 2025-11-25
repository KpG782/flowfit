/// Enum representing different meal types throughout the day
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  /// Get a human-readable display name for the meal type
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}
