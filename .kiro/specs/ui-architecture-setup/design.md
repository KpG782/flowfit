# Design Document

## Overview

This design document outlines the architecture for FlowFit's UI-only implementation with complete navigation flows, mock data repositories, and clean architecture patterns. The system will provide a fully functional user interface ready for backend integration while preserving the existing watch-to-phone heart rate streaming functionality.

The architecture follows clean architecture principles with clear separation between domain (business logic), data (repositories), and presentation (UI) layers. Riverpod will manage state and dependency injection, making it easy to swap mock implementations with real backend services.

## Architecture

### Layer Structure

```
lib/
├── core/
│   ├── domain/              # Business entities & interfaces
│   │   ├── entities/        # Core business objects
│   │   └── repositories/    # Repository interfaces
│   ├── data/                # Data layer implementations
│   │   ├── repositories/    # Mock repository implementations
│   │   └── models/          # Data transfer objects
│   └── providers/           # Riverpod providers
│       ├── repositories/    # Repository providers
│       ├── services/        # Service providers
│       └── state/           # State providers
├── features/                # Feature modules
│   ├── fitness/
│   │   ├── domain/          # Fitness entities & interfaces
│   │   ├── data/            # Mock fitness repositories
│   │   ├── providers/       # Fitness state providers
│   │   └── presentation/    # UI screens & widgets
│   ├── nutrition/
│   ├── sleep/
│   ├── mood/
│   ├── reports/
│   └── profile/
├── shared/                  # Shared resources
│   ├── widgets/             # Reusable UI components
│   ├── navigation/          # Routing configuration
│   ├── theme/               # App theming
│   └── utils/               # Helper functions
└── services/                # Platform services (preserved)
    └── watch_bridge.dart    # Existing Samsung Health SDK integration
```

### Architectural Principles

1. **Dependency Rule**: Dependencies point inward. Domain layer has no dependencies. Data layer depends on domain. Presentation depends on domain.

2. **Interface Segregation**: Each feature defines its own repository interfaces in the domain layer.

3. **Dependency Injection**: Riverpod providers inject dependencies, making it easy to swap implementations.

4. **Single Responsibility**: Each class has one reason to change.

5. **Backend-Ready**: All mock implementations can be replaced with real backend calls without changing UI code.

## Components and Interfaces

### Domain Layer

#### Core Entities

```dart
// lib/core/domain/entities/user_profile.dart
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
}

// lib/features/fitness/domain/entities/workout.dart
class Workout {
  final String id;
  final String userId;
  final WorkoutType type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double? distance;  // in kilometers
  final int? calories;
  final List<HeartRatePoint> heartRateData;
  final Map<String, dynamic>? metadata;
}

// lib/features/fitness/domain/entities/workout_type.dart
enum WorkoutType {
  running,
  walking,
  cycling,
  strength,
  yoga,
  other
}

// lib/features/fitness/domain/entities/heart_rate_point.dart
class HeartRatePoint {
  final DateTime timestamp;
  final int bpm;
  final List<int> ibiValues;
}

// lib/features/nutrition/domain/entities/food_log.dart
class FoodLog {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String foodName;
  final int calories;
  final Macros macros;
  final MealType mealType;
}

// lib/features/nutrition/domain/entities/macros.dart
class Macros {
  final double carbohydrates;  // in grams
  final double protein;        // in grams
  final double fat;            // in grams
}

// lib/features/sleep/domain/entities/sleep_session.dart
class SleepSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final SleepQuality quality;
  final List<SleepStage> stages;
  final int interruptions;
}

// lib/features/mood/domain/entities/mood_entry.dart
class MoodEntry {
  final String id;
  final String userId;
  final DateTime timestamp;
  final MoodType mood;
  final String? notes;
}

// lib/features/profile/domain/entities/streak.dart
class Streak {
  final StreakType type;
  final int currentCount;
  final int longestCount;
  final DateTime? lastActivityDate;
  final List<DateTime> activityDates;
}
```

#### Repository Interfaces

```dart
// lib/features/fitness/domain/repositories/workout_repository.dart
abstract class WorkoutRepository {
  /// Get workout history for a date range
  Future<List<Workout>> getWorkoutHistory({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Get a specific workout by ID
  Future<Workout?> getWorkoutById(String id);
  
  /// Save a new workout
  Future<void> saveWorkout(Workout workout);
  
  /// Update an existing workout
  Future<void> updateWorkout(Workout workout);
  
  /// Delete a workout
  Future<void> deleteWorkout(String id);
  
  /// Get active workout session (if any)
  Future<Workout?> getActiveWorkout();
}

// lib/features/fitness/domain/repositories/heart_rate_repository.dart
abstract class HeartRateRepository {
  /// Get real-time heart rate stream from watch
  Stream<HeartRateData> getHeartRateStream();
  
  /// Get historical heart rate data
  Future<List<HeartRatePoint>> getHeartRateHistory({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Save heart rate data point
  Future<void> saveHeartRateData(HeartRatePoint data);
  
  /// Get current heart rate reading
  Future<HeartRatePoint?> getCurrentHeartRate();
}

// lib/features/nutrition/domain/repositories/nutrition_repository.dart
abstract class NutritionRepository {
  /// Get food logs for a specific date
  Future<List<FoodLog>> getFoodLogsForDate(DateTime date);
  
  /// Add a food log entry
  Future<void> addFoodLog(FoodLog log);
  
  /// Update a food log entry
  Future<void> updateFoodLog(FoodLog log);
  
  /// Delete a food log entry
  Future<void> deleteFoodLog(String id);
  
  /// Get daily nutrition summary
  Future<DailyNutritionSummary> getDailySummary(DateTime date);
}

// lib/features/sleep/domain/repositories/sleep_repository.dart
abstract class SleepRepository {
  /// Get sleep sessions for a date range
  Future<List<SleepSession>> getSleepSessions({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Save a sleep session
  Future<void> saveSleepSession(SleepSession session);
  
  /// Get active sleep session (if any)
  Future<SleepSession?> getActiveSleepSession();
  
  /// Update sleep session
  Future<void> updateSleepSession(SleepSession session);
}

// lib/features/mood/domain/repositories/mood_repository.dart
abstract class MoodRepository {
  /// Get mood entries for a date range
  Future<List<MoodEntry>> getMoodEntries({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Add a mood entry
  Future<void> addMoodEntry(MoodEntry entry);
  
  /// Get workout recommendations based on mood
  Future<List<WorkoutRecommendation>> getRecommendationsForMood(MoodType mood);
}

// lib/features/profile/domain/repositories/profile_repository.dart
abstract class ProfileRepository {
  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId);
  
  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile);
  
  /// Get user streaks
  Future<List<Streak>> getUserStreaks(String userId);
  
  /// Update streak data
  Future<void> updateStreak(Streak streak);
}
```

### Data Layer

#### Mock Repository Implementations

```dart
// lib/features/fitness/data/repositories/mock_workout_repository.dart
class MockWorkoutRepository implements WorkoutRepository {
  // In-memory storage for mock data
  final List<Workout> _workouts = _generateMockWorkouts();
  Workout? _activeWorkout;
  
  @override
  Future<List<Workout>> getWorkoutHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // TODO: Backend integration - Replace with Supabase query
    // await supabase.from('workouts')
    //   .select()
    //   .gte('start_time', startDate.toIso8601String())
    //   .lte('start_time', endDate.toIso8601String());
    
    await Future.delayed(Duration(milliseconds: 300)); // Simulate network delay
    return _workouts.where((w) =>
      w.startTime.isAfter(startDate) && w.startTime.isBefore(endDate)
    ).toList();
  }
  
  @override
  Future<Workout?> getWorkoutById(String id) async {
    // TODO: Backend integration - Replace with Supabase query
    await Future.delayed(Duration(milliseconds: 200));
    return _workouts.firstWhere((w) => w.id == id);
  }
  
  @override
  Future<void> saveWorkout(Workout workout) async {
    // TODO: Backend integration - Replace with Supabase insert
    // await supabase.from('workouts').insert(workout.toJson());
    await Future.delayed(Duration(milliseconds: 300));
    _workouts.add(workout);
  }
  
  // ... other methods with similar TODO comments
  
  static List<Workout> _generateMockWorkouts() {
    // Generate 15 sample workouts
    return List.generate(15, (index) {
      final daysAgo = index;
      final startTime = DateTime.now().subtract(Duration(days: daysAgo, hours: 8));
      return Workout(
        id: 'workout_$index',
        userId: 'user_1',
        type: WorkoutType.values[index % WorkoutType.values.length],
        startTime: startTime,
        endTime: startTime.add(Duration(minutes: 30 + index * 5)),
        duration: Duration(minutes: 30 + index * 5),
        distance: (index % 2 == 0) ? 5.0 + index * 0.5 : null,
        calories: 200 + index * 20,
        heartRateData: _generateMockHeartRateData(startTime, 30 + index * 5),
        metadata: {},
      );
    });
  }
}

// lib/features/fitness/data/repositories/mock_heart_rate_repository.dart
class MockHeartRateRepository implements HeartRateRepository {
  final WatchBridgeService _watchBridge;
  
  MockHeartRateRepository(this._watchBridge);
  
  @override
  Stream<HeartRateData> getHeartRateStream() {
    // IMPORTANT: Use existing watch bridge service for real data
    // This is NOT mocked - it uses the actual Samsung Health SDK
    return _watchBridge.heartRateStream;
  }
  
  @override
  Future<List<HeartRatePoint>> getHeartRateHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // TODO: Backend integration - Replace with Supabase query
    // await supabase.from('heart_rate_data')
    //   .select()
    //   .gte('timestamp', startDate.toIso8601String())
    //   .lte('timestamp', endDate.toIso8601String());
    
    await Future.delayed(Duration(milliseconds: 300));
    return _generateMockHeartRateHistory(startDate, endDate);
  }
  
  @override
  Future<void> saveHeartRateData(HeartRatePoint data) async {
    // TODO: Backend integration - Replace with Supabase insert
    // await supabase.from('heart_rate_data').insert(data.toJson());
    await Future.delayed(Duration(milliseconds: 200));
  }
  
  @override
  Future<HeartRatePoint?> getCurrentHeartRate() async {
    // Use watch bridge for current reading
    final data = await _watchBridge.getCurrentHeartRate();
    if (data == null) return null;
    
    return HeartRatePoint(
      timestamp: data.timestamp,
      bpm: data.bpm ?? 0,
      ibiValues: data.ibiValues,
    );
  }
}
```

### Presentation Layer

#### Riverpod Providers

```dart
// lib/core/providers/repositories/workout_repository_provider.dart
@riverpod
WorkoutRepository workoutRepository(WorkoutRepositoryRef ref) {
  return MockWorkoutRepository();
  // TODO: Backend integration - Replace with real implementation
  // return SupabaseWorkoutRepository(ref.watch(supabaseClientProvider));
}

// lib/core/providers/repositories/heart_rate_repository_provider.dart
@riverpod
HeartRateRepository heartRateRepository(HeartRateRepositoryRef ref) {
  final watchBridge = ref.watch(watchBridgeServiceProvider);
  return MockHeartRateRepository(watchBridge);
  // TODO: Backend integration - Replace with real implementation
  // return SupabaseHeartRateRepository(
  //   ref.watch(supabaseClientProvider),
  //   watchBridge,
  // );
}

// lib/core/providers/services/watch_bridge_provider.dart
@riverpod
WatchBridgeService watchBridgeService(WatchBridgeServiceRef ref) {
  final service = WatchBridgeService();
  ref.onDispose(() => service.dispose());
  return service;
}

// lib/core/providers/state/heart_rate_state_provider.dart
@riverpod
Stream<HeartRateData> heartRateStream(HeartRateStreamRef ref) {
  final repository = ref.watch(heartRateRepositoryProvider);
  return repository.getHeartRateStream();
}

// lib/features/fitness/providers/workout_list_provider.dart
@riverpod
Future<List<Workout>> workoutList(
  WorkoutListRef ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getWorkoutHistory(
    startDate: startDate,
    endDate: endDate,
  );
}

// lib/features/fitness/providers/active_workout_provider.dart
@riverpod
class ActiveWorkoutNotifier extends _$ActiveWorkoutNotifier {
  @override
  Future<Workout?> build() async {
    final repository = ref.watch(workoutRepositoryProvider);
    return repository.getActiveWorkout();
  }
  
  Future<void> startWorkout(WorkoutType type) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final workout = Workout(
        id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_1',
        type: type,
        startTime: DateTime.now(),
        endTime: DateTime.now(), // Will be updated on completion
        duration: Duration.zero,
        heartRateData: [],
        metadata: {},
      );
      
      final repository = ref.read(workoutRepositoryProvider);
      await repository.saveWorkout(workout);
      return workout;
    });
  }
  
  Future<void> stopWorkout() async {
    final current = state.value;
    if (current == null) return;
    
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = current.copyWith(
        endTime: DateTime.now(),
        duration: DateTime.now().difference(current.startTime),
      );
      
      final repository = ref.read(workoutRepositoryProvider);
      await repository.updateWorkout(updated);
      return null;
    });
  }
}
```

#### Screen Structure

```dart
// lib/features/fitness/presentation/screens/workout_history_screen.dart
class WorkoutHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = DateTime.now().subtract(Duration(days: 30));
    final endDate = DateTime.now();
    
    final workoutsAsync = ref.watch(workoutListProvider(
      startDate: startDate,
      endDate: endDate,
    ));
    
    return Scaffold(
      appBar: AppBar(title: Text('Workout History')),
      body: workoutsAsync.when(
        data: (workouts) => WorkoutListView(workouts: workouts),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(error: error),
      ),
    );
  }
}

// lib/features/fitness/presentation/screens/workout_session_screen.dart
class WorkoutSessionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkoutAsync = ref.watch(activeWorkoutNotifierProvider);
    final heartRateAsync = ref.watch(heartRateStreamProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Workout Session')),
      body: Column(
        children: [
          // Timer display
          WorkoutTimerWidget(workout: activeWorkoutAsync.value),
          
          // Live heart rate from watch
          heartRateAsync.when(
            data: (heartRate) => LiveHeartRateWidget(
              bpm: heartRate.bpm,
              status: heartRate.status,
            ),
            loading: () => Text('Connecting to watch...'),
            error: (error, stack) => Text('Heart rate unavailable'),
          ),
          
          // Workout controls
          WorkoutControlsWidget(
            onStart: () => ref.read(activeWorkoutNotifierProvider.notifier)
              .startWorkout(WorkoutType.running),
            onStop: () => ref.read(activeWorkoutNotifierProvider.notifier)
              .stopWorkout(),
          ),
        ],
      ),
    );
  }
}
```

## Data Models

### Entity Relationships

```
UserProfile
  ├── Workouts (1:N)
  ├── FoodLogs (1:N)
  ├── SleepSessions (1:N)
  ├── MoodEntries (1:N)
  └── Streaks (1:N)

Workout
  ├── HeartRatePoints (1:N)
  └── WorkoutType (N:1)

SleepSession
  └── SleepStages (1:N)

Streak
  └── ActivityDates (1:N)
```

### Mock Data Generation

Mock data will be generated with realistic patterns:

- **Workouts**: 15 sample workouts over the past 30 days with varying types, durations, and metrics
- **Heart Rate**: Historical data with realistic BPM ranges (60-180) and variability
- **Food Logs**: Sample meals with accurate macro calculations
- **Sleep Sessions**: 7 days of sleep data with realistic durations (6-9 hours) and quality ratings
- **Mood Entries**: Various mood states distributed over time
- **Streaks**: Current and historical streak data for motivation features

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After reviewing all testable properties from the prework, I've identified several areas where properties can be consolidated:

**Redundancies Identified:**
- Properties 5.1, 5.2, and 14.4 all test heart rate data flow from watch to phone - these can be combined into one comprehensive property
- Properties 6.2, 6.4 test workout display completeness - can be combined
- Properties 8.3, 8.4, 8.5 all test nutrition display - can be consolidated
- Properties 10.2, 10.3, 10.4 all test report chart completeness - can be combined
- Properties 13.1, 13.2, 13.5 all test streak tracking - can be consolidated

**Consolidated Properties:**
The following correctness properties represent unique validation value after removing redundancies:

### Correctness Properties

Property 1: Navigation transitions work correctly
*For any* bottom navigation item, tapping it should navigate to the corresponding feature screen and allow back navigation to return to the previous screen
**Validates: Requirements 1.2, 1.5**

Property 2: All feature screens display mock data
*For any* feature screen in the app, navigating to it should render without errors and display mock data in the UI
**Validates: Requirements 1.3**

Property 3: Mock repositories return valid data
*For any* mock repository method call, the returned data should be non-null and conform to the domain entity structure
**Validates: Requirements 3.2, 3.3**

Property 4: Heart rate data flows from watch to phone
*For any* heart rate reading from the Samsung Health Sensor SDK, the data should stream through the Watch Bridge, transmit to the phone, and appear in the phone UI within 2 seconds
**Validates: Requirements 5.1, 5.2, 5.3, 5.4, 14.2, 14.4**

Property 5: Workout display completeness
*For any* workout in the history list, the UI should display workout type, duration, distance, calories, and tapping it should navigate to a detail screen showing heart rate data, pace, and route placeholders
**Validates: Requirements 6.2, 6.3, 6.4**

Property 6: Active workout displays live metrics
*For any* active workout session, the UI should display elapsed time, distance, and current heart rate, and pausing should stop the timer while preserving metrics
**Validates: Requirements 7.2, 7.3, 7.5**

Property 7: Nutrition data aggregation and display
*For any* date with food logs, the daily nutrition view should display correct totals for calories, carbohydrates, protein, and fat, along with progress indicators when goals are set
**Validates: Requirements 8.3, 8.4, 8.5**

Property 8: Sleep session display completeness
*For any* sleep session in history, the UI should display duration and quality metrics, and the detail view should show sleep stages and interruptions
**Validates: Requirements 9.2, 9.4**

Property 9: Profile display completeness
*For any* user profile, the profile screen should display username, profile photo, sex, date of birth, location, email, and when weight tracking is enabled, current and goal weight fields
**Validates: Requirements 11.2, 11.5**

Property 10: Mood-based workout recommendations
*For any* selected mood, the system should display workout recommendations filtered by intensity and type matching that mood state
**Validates: Requirements 12.2, 12.4**

Property 11: Mood history display
*For any* date range with mood entries, the mood history should show all entries with timestamps and display mood trends in the reports section
**Validates: Requirements 12.3, 12.5**

Property 12: Streak tracking and display
*For any* user activity data, the system should calculate current streak counts for workout, nutrition, and app usage separately, display them in a calendar-style UI, and show achievement badges when milestones are reached
**Validates: Requirements 13.1, 13.2, 13.3, 13.5**

Property 13: Streak break empathy
*For any* broken streak, the system should display empathetic messaging encouraging continuation rather than punitive messaging
**Validates: Requirements 13.4**

Property 14: Report chart completeness
*For any* report type (cardio, strength, nutrition), the reports screen should display all required charts including trends, frequency, distribution, and progression visualizations
**Validates: Requirements 10.2, 10.3, 10.4**

## Error Handling

### Error Types

1. **Network Errors** (Future Backend Integration)
   - Connection timeouts
   - Server unavailable
   - Invalid responses
   - Strategy: Display user-friendly error messages with retry options

2. **Watch Connection Errors**
   - Watch disconnected
   - Samsung Health SDK unavailable
   - Permission denied
   - Strategy: Show connection status indicator, guide user to reconnect

3. **Data Validation Errors**
   - Invalid input formats
   - Out-of-range values
   - Missing required fields
   - Strategy: Inline validation with clear error messages

4. **State Management Errors**
   - Provider initialization failures
   - Stream errors
   - State inconsistencies
   - Strategy: Error boundaries with fallback UI

### Error Handling Patterns

```dart
// Repository error handling
class RepositoryException implements Exception {
  final String message;
  final RepositoryErrorType type;
  final dynamic originalError;
  
  RepositoryException({
    required this.message,
    required this.type,
    this.originalError,
  });
}

enum RepositoryErrorType {
  notFound,
  validationError,
  connectionError,
  permissionDenied,
  unknown,
}

// UI error handling with Riverpod
@riverpod
Future<List<Workout>> workoutList(WorkoutListRef ref) async {
  try {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getWorkoutHistory(
      startDate: DateTime.now().subtract(Duration(days: 30)),
      endDate: DateTime.now(),
    );
  } on RepositoryException catch (e) {
    // Log error for debugging
    debugPrint('Repository error: ${e.message}');
    
    // Rethrow for UI to handle
    rethrow;
  } catch (e) {
    // Wrap unknown errors
    throw RepositoryException(
      message: 'Failed to load workouts',
      type: RepositoryErrorType.unknown,
      originalError: e,
    );
  }
}

// Error display in UI
Widget build(BuildContext context, WidgetRef ref) {
  final workoutsAsync = ref.watch(workoutListProvider);
  
  return workoutsAsync.when(
    data: (workouts) => WorkoutListView(workouts: workouts),
    loading: () => LoadingIndicator(),
    error: (error, stack) {
      if (error is RepositoryException) {
        return ErrorView(
          message: error.message,
          onRetry: () => ref.invalidate(workoutListProvider),
        );
      }
      return ErrorView(
        message: 'An unexpected error occurred',
        onRetry: () => ref.invalidate(workoutListProvider),
      );
    },
  );
}
```

### Watch Bridge Error Handling

The existing Watch Bridge service already implements comprehensive error handling:
- Retry logic with exponential backoff
- Timeout handling
- Permission error mapping
- Connection state monitoring

The UI layer will integrate with these error states:

```dart
// Connection status display
@riverpod
Stream<ConnectionState> watchConnectionState(WatchConnectionStateRef ref) {
  final watchBridge = ref.watch(watchBridgeServiceProvider);
  return watchBridge.connectionStateStream;
}

// UI integration
Widget build(BuildContext context, WidgetRef ref) {
  final connectionAsync = ref.watch(watchConnectionStateProvider);
  
  return connectionAsync.when(
    data: (state) => ConnectionStatusBadge(
      isConnected: state.isConnected,
      nodeCount: state.nodeCount,
      lastSyncTime: state.lastSyncTime,
    ),
    loading: () => ConnectionStatusBadge.loading(),
    error: (error, stack) => ConnectionStatusBadge.error(),
  );
}
```

## Testing Strategy

### Dual Testing Approach

The testing strategy combines unit tests and property-based tests to provide comprehensive coverage:

**Unit Tests** verify:
- Specific examples and edge cases
- UI widget rendering
- Navigation flows
- Mock data generation
- Error handling scenarios

**Property-Based Tests** verify:
- Universal properties across all inputs
- Data flow integrity
- State management correctness
- Repository contract compliance

### Property-Based Testing Setup

**Library**: We will use the `test` package with custom property testing utilities, as Flutter doesn't have a mature PBT library. For Dart, we'll implement a lightweight property testing framework using generators.

**Configuration**: Each property-based test will run a minimum of 100 iterations to ensure adequate coverage of the input space.

**Tagging**: Each property-based test must include a comment tag in this format:
```dart
// **Feature: ui-architecture-setup, Property 1: Navigation transitions work correctly**
test('navigation transitions work correctly', () {
  // Property test implementation
});
```

### Unit Testing Strategy

Unit tests will cover:

1. **Widget Tests**
   - Screen rendering without errors
   - Widget tree structure validation
   - User interaction handling
   - State updates reflected in UI

2. **Repository Tests**
   - Mock data generation correctness
   - Data structure validation
   - Error handling
   - Async operation completion

3. **Provider Tests**
   - Provider initialization
   - State updates
   - Dependency injection
   - Stream handling

4. **Navigation Tests**
   - Route transitions
   - Back navigation
   - Deep linking (future)
   - Navigation state preservation

### Example Test Structure

```dart
// Unit test example
void main() {
  group('WorkoutHistoryScreen', () {
    testWidgets('displays workout list when data is available', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: WorkoutHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(WorkoutListView), findsOneWidget);
      expect(find.byType(WorkoutCard), findsWidgets);
    });
    
    testWidgets('displays empty state when no workouts exist', (tester) async {
      // Edge case test
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(
            MockWorkoutRepository(workouts: []),
          ),
        ],
      );
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: WorkoutHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No workouts yet'), findsOneWidget);
    });
  });
}

// Property-based test example
// **Feature: ui-architecture-setup, Property 3: Mock repositories return valid data**
void main() {
  group('Mock Repository Properties', () {
    test('all mock repositories return valid data', () async {
      final repositories = [
        MockWorkoutRepository(),
        MockNutritionRepository(),
        MockSleepRepository(),
        MockMoodRepository(),
      ];
      
      // Run 100 iterations
      for (var i = 0; i < 100; i++) {
        for (final repo in repositories) {
          // Test that data is non-null and valid
          final data = await repo.getData();
          expect(data, isNotNull);
          expect(data, isA<ValidEntity>());
        }
      }
    });
  });
}
```

### Integration Testing

While this phase focuses on UI-only implementation, integration test structure will be prepared:

1. **Watch-to-Phone Integration**
   - Heart rate data flow end-to-end
   - Connection state management
   - Data synchronization

2. **Navigation Integration**
   - Complete user journeys
   - Multi-screen workflows
   - State persistence across navigation

3. **Backend Integration Points** (Future)
   - Supabase authentication flow
   - Real-time data subscriptions
   - CRUD operations
   - File uploads

### Test Coverage Goals

- **Unit Test Coverage**: 80%+ for business logic and repositories
- **Widget Test Coverage**: 70%+ for UI components
- **Property Test Coverage**: All 14 correctness properties implemented
- **Integration Test Coverage**: Critical user flows (watch sync, workout tracking, nutrition logging)

## Navigation Architecture

### Router Configuration

Using `go_router` for type-safe navigation with deep linking support:

```dart
// lib/shared/navigation/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => DashboardScreen(),
    ),
    GoRoute(
      path: '/fitness',
      name: 'fitness',
      builder: (context, state) => FitnessScreen(),
      routes: [
        GoRoute(
          path: 'history',
          name: 'workout-history',
          builder: (context, state) => WorkoutHistoryScreen(),
        ),
        GoRoute(
          path: 'workout/:id',
          name: 'workout-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return WorkoutDetailScreen(workoutId: id);
          },
        ),
        GoRoute(
          path: 'session',
          name: 'workout-session',
          builder: (context, state) => WorkoutSessionScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/nutrition',
      name: 'nutrition',
      builder: (context, state) => NutritionScreen(),
      routes: [
        GoRoute(
          path: 'log',
          name: 'food-log',
          builder: (context, state) => FoodLogScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/sleep',
      name: 'sleep',
      builder: (context, state) => SleepScreen(),
      routes: [
        GoRoute(
          path: 'session/:id',
          name: 'sleep-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return SleepDetailScreen(sessionId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/mood',
      name: 'mood',
      builder: (context, state) => MoodScreen(),
      routes: [
        GoRoute(
          path: 'log',
          name: 'mood-log',
          builder: (context, state) => MoodLogScreen(),
        ),
        GoRoute(
          path: 'recommendations',
          name: 'mood-recommendations',
          builder: (context, state) {
            final mood = state.extra as MoodType;
            return MoodRecommendationsScreen(mood: mood);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => ReportsScreen(),
      routes: [
        GoRoute(
          path: 'cardio',
          name: 'cardio-report',
          builder: (context, state) => CardioReportScreen(),
        ),
        GoRoute(
          path: 'strength',
          name: 'strength-report',
          builder: (context, state) => StrengthReportScreen(),
        ),
        GoRoute(
          path: 'nutrition',
          name: 'nutrition-report',
          builder: (context, state) => NutritionReportScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => ProfileScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          name: 'settings',
          builder: (context, state) => SettingsScreen(),
        ),
        GoRoute(
          path: 'account',
          name: 'account',
          builder: (context, state) => AccountScreen(),
        ),
        GoRoute(
          path: 'streaks',
          name: 'streaks',
          builder: (context, state) => StreaksScreen(),
        ),
      ],
    ),
  ],
);
```

### Bottom Navigation Structure

```dart
// lib/shared/widgets/app_bottom_navigation.dart
class AppBottomNavigation extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return BottomNavigationBar(
      currentIndex: _getIndexForRoute(currentRoute),
      onTap: (index) => _navigateToIndex(context, index),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Fitness',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
  
  int _getIndexForRoute(String route) {
    if (route.startsWith('/home')) return 0;
    if (route.startsWith('/fitness')) return 1;
    if (route.startsWith('/reports')) return 2;
    if (route.startsWith('/profile')) return 3;
    return 0;
  }
  
  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/fitness');
        break;
      case 2:
        context.go('/reports');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
```

## Theme and Styling

### Design System

```dart
// lib/shared/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}
```

### Reusable Components

Key shared widgets to implement:

1. **StatCard**: Display metric cards on dashboard
2. **ChartCard**: Wrapper for fl_chart visualizations
3. **EmptyStateView**: Consistent empty state messaging
4. **ErrorView**: Error display with retry functionality
5. **LoadingIndicator**: Consistent loading states
6. **ConnectionStatusBadge**: Watch connection indicator
7. **LiveHeartRateWidget**: Real-time BPM display
8. **StreakCalendar**: Calendar view for streak tracking
9. **WorkoutCard**: Workout list item
10. **FoodLogCard**: Food entry list item
11. **SleepSessionCard**: Sleep session list item
12. **MoodSelector**: Mood selection interface

## Backend Integration Points

All backend integration points will be marked with TODO comments following this pattern:

```dart
// TODO: Backend integration - Supabase Authentication
// Replace with: await supabase.auth.signIn(email: email, password: password)

// TODO: Backend integration - Real-time subscription
// Replace with: supabase.from('workouts').stream(primaryKey: ['id'])

// TODO: Backend integration - CRUD operation
// Replace with: await supabase.from('workouts').insert(workout.toJson())

// TODO: Backend integration - File upload
// Replace with: await supabase.storage.from('avatars').upload(path, file)
```

### Integration Checklist

When implementing real backend:

1. **Authentication**
   - [ ] Replace mock auth with Supabase auth
   - [ ] Implement token refresh
   - [ ] Add session management
   - [ ] Handle auth state changes

2. **Data Persistence**
   - [ ] Replace mock repositories with Supabase repositories
   - [ ] Implement CRUD operations
   - [ ] Add optimistic updates
   - [ ] Handle conflicts

3. **Real-time Updates**
   - [ ] Set up Supabase channels
   - [ ] Subscribe to relevant tables
   - [ ] Handle real-time events
   - [ ] Manage subscriptions lifecycle

4. **File Storage**
   - [ ] Implement profile photo upload
   - [ ] Add workout route images
   - [ ] Handle file compression
   - [ ] Implement caching

5. **Watch Sync**
   - [ ] Persist watch data to Supabase
   - [ ] Implement batch sync
   - [ ] Handle sync conflicts
   - [ ] Add offline queue

## Implementation Phases

### Phase 1: Core Architecture Setup
- Set up folder structure
- Create domain entities
- Define repository interfaces
- Configure Riverpod providers
- Set up navigation with go_router

### Phase 2: Mock Data Layer
- Implement mock repositories
- Generate realistic sample data
- Add error simulation
- Test repository contracts

### Phase 3: Dashboard and Navigation
- Implement dashboard screen
- Create bottom navigation
- Add connection status indicator
- Integrate live heart rate display

### Phase 4: Fitness Features
- Workout history screen
- Workout detail screen
- Workout session screen
- Heart rate integration

### Phase 5: Nutrition Features
- Food logging screen
- Daily nutrition summary
- Nutrition reports
- Macro tracking

### Phase 6: Sleep Features
- Sleep tracking screen
- Sleep history
- Sleep detail view
- Calendar navigation

### Phase 7: Mood and Recommendations
- Mood logging
- Mood history
- Workout recommendations
- Mood-based filtering

### Phase 8: Reports and Analytics
- Reports dashboard
- Cardio analytics
- Strength analytics
- Nutrition analytics
- Chart implementations

### Phase 9: Profile and Settings
- Profile screen
- Settings screen
- Account management
- Streak tracking
- Weight tracking

### Phase 10: Polish and Testing
- Theme refinement
- Animations
- Error handling
- Unit tests
- Property-based tests
- Integration tests

## Success Criteria

The implementation will be considered complete when:

1. ✅ All screens from requirements are implemented and navigable
2. ✅ Live heart rate data from watch displays on phone dashboard
3. ✅ Mock repositories provide realistic data for all features
4. ✅ Clean architecture layers are properly separated
5. ✅ Riverpod providers manage all state and dependencies
6. ✅ Navigation flows work end-to-end with back navigation
7. ✅ All backend integration points are marked with TODO comments
8. ✅ Error handling is implemented consistently
9. ✅ Theme and styling are consistent across all screens
10. ✅ All 14 correctness properties have corresponding tests
11. ✅ Unit test coverage exceeds 70%
12. ✅ Watch Bridge service remains functional and unmodified
13. ✅ Mock implementations can be easily swapped with real backend
14. ✅ No business logic exists in UI layer
