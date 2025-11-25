import 'macros.dart';

/// Domain entity representing a daily nutrition summary
class DailyNutritionSummary {
  final DateTime date;
  final int totalCalories;
  final Macros totalMacros;
  final int? calorieGoal;
  final Macros? macroGoals;

  const DailyNutritionSummary({
    required this.date,
    required this.totalCalories,
    required this.totalMacros,
    this.calorieGoal,
    this.macroGoals,
  });

  /// Calculate percentage of calorie goal achieved
  double? get calorieProgress {
    if (calorieGoal == null || calorieGoal == 0) return null;
    return (totalCalories / calorieGoal!) * 100;
  }

  /// Calculate percentage of carb goal achieved
  double? get carbProgress {
    if (macroGoals == null || macroGoals!.carbohydrates == 0) return null;
    return (totalMacros.carbohydrates / macroGoals!.carbohydrates) * 100;
  }

  /// Calculate percentage of protein goal achieved
  double? get proteinProgress {
    if (macroGoals == null || macroGoals!.protein == 0) return null;
    return (totalMacros.protein / macroGoals!.protein) * 100;
  }

  /// Calculate percentage of fat goal achieved
  double? get fatProgress {
    if (macroGoals == null || macroGoals!.fat == 0) return null;
    return (totalMacros.fat / macroGoals!.fat) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyNutritionSummary &&
        other.date == date &&
        other.totalCalories == totalCalories &&
        other.totalMacros == totalMacros &&
        other.calorieGoal == calorieGoal &&
        other.macroGoals == macroGoals;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      totalCalories,
      totalMacros,
      calorieGoal,
      macroGoals,
    );
  }
}
