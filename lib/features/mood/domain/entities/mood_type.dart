/// Enum representing different mood states
enum MoodType {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
  anxious,
  stressed,
  energetic,
  tired,
  calm;

  /// Get a human-readable display name for the mood type
  String get displayName {
    switch (this) {
      case MoodType.veryHappy:
        return 'Very Happy';
      case MoodType.happy:
        return 'Happy';
      case MoodType.neutral:
        return 'Neutral';
      case MoodType.sad:
        return 'Sad';
      case MoodType.verySad:
        return 'Very Sad';
      case MoodType.anxious:
        return 'Anxious';
      case MoodType.stressed:
        return 'Stressed';
      case MoodType.energetic:
        return 'Energetic';
      case MoodType.tired:
        return 'Tired';
      case MoodType.calm:
        return 'Calm';
    }
  }

  /// Get an emoji representation of the mood
  String get emoji {
    switch (this) {
      case MoodType.veryHappy:
        return '😄';
      case MoodType.happy:
        return '🙂';
      case MoodType.neutral:
        return '😐';
      case MoodType.sad:
        return '😔';
      case MoodType.verySad:
        return '😢';
      case MoodType.anxious:
        return '😰';
      case MoodType.stressed:
        return '😫';
      case MoodType.energetic:
        return '⚡';
      case MoodType.tired:
        return '😴';
      case MoodType.calm:
        return '😌';
    }
  }

  /// Get recommended workout intensity for this mood
  /// Returns a value from 1 (low) to 5 (high)
  int get recommendedIntensity {
    switch (this) {
      case MoodType.veryHappy:
      case MoodType.energetic:
        return 5;
      case MoodType.happy:
        return 4;
      case MoodType.neutral:
      case MoodType.calm:
        return 3;
      case MoodType.stressed:
      case MoodType.anxious:
        return 2;
      case MoodType.sad:
      case MoodType.verySad:
      case MoodType.tired:
        return 1;
    }
  }
}
