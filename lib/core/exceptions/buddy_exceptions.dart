/// Base exception for Buddy onboarding-related errors
class BuddyException implements Exception {
  final String message;
  final String? userFriendlyMessage;
  final Object? originalError;
  final StackTrace? stackTrace;

  BuddyException(
    this.message, {
    this.userFriendlyMessage,
    this.originalError,
    this.stackTrace,
  });

  /// Get a user-friendly error message
  String get friendlyMessage =>
      userFriendlyMessage ?? 'Oops! Something went wrong with your Buddy.';

  @override
  String toString() => 'BuddyException: $message';
}

/// Exception thrown when Buddy name validation fails
class BuddyNameValidationException extends BuddyException {
  BuddyNameValidationException(
    super.message, {
    super.userFriendlyMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get friendlyMessage =>
      userFriendlyMessage ?? 'Please give your buddy a valid name!';

  @override
  String toString() => 'BuddyNameValidationException: $message';
}

/// Exception thrown when network operations fail
class BuddyNetworkException extends BuddyException {
  final bool isTimeout;
  final bool canRetry;

  BuddyNetworkException(
    super.message, {
    super.userFriendlyMessage,
    super.originalError,
    super.stackTrace,
    this.isTimeout = false,
    this.canRetry = true,
  });

  @override
  String get friendlyMessage =>
      userFriendlyMessage ??
      'Oops! We couldn\'t connect. Check your internet connection.';

  @override
  String toString() => 'BuddyNetworkException: $message';
}

/// Exception thrown when saving Buddy profile fails
class BuddySaveException extends BuddyException {
  final bool savedLocally;

  BuddySaveException(
    super.message, {
    super.userFriendlyMessage,
    super.originalError,
    super.stackTrace,
    this.savedLocally = false,
  });

  @override
  String get friendlyMessage => savedLocally
      ? 'Your Buddy is saved! We\'ll sync when you\'re back online.'
      : userFriendlyMessage ??
            'Oops! We couldn\'t save your Buddy. Let\'s try again!';

  @override
  String toString() => 'BuddySaveException: $message';
}

/// Exception thrown when user is not authenticated
class BuddyAuthException extends BuddyException {
  BuddyAuthException(
    super.message, {
    super.userFriendlyMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get friendlyMessage =>
      userFriendlyMessage ??
      'Oops! You need to be logged in to create your Buddy.';

  @override
  String toString() => 'BuddyAuthException: $message';
}

/// Exception thrown when required onboarding data is missing
class BuddyDataException extends BuddyException {
  final List<String> missingFields;

  BuddyDataException(
    super.message, {
    super.userFriendlyMessage,
    super.originalError,
    super.stackTrace,
    this.missingFields = const [],
  });

  @override
  String get friendlyMessage =>
      userFriendlyMessage ??
      'Oops! Some information is missing. Let\'s go back and fill it in!';

  @override
  String toString() => 'BuddyDataException: $message';
}
