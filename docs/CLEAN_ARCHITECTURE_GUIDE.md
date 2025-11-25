# Clean Architecture with Riverpod - FlowFit

## Overview

FlowFit uses **Clean Architecture** with **Riverpod** for state management. This provides:
- Clear separation of concerns
- Testable business logic
- Independent layers
- Scalable codebase

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, UI State)           │
│  - Uses ConsumerWidget                  │
│  - Watches providers                    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Provider Layer                  │
│  (Riverpod Providers)                   │
│  - State providers                      │
│  - Repository providers                 │
│  - Service providers                    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Domain Layer                    │
│  (Business Logic)                       │
│  - Entities (HeartRateData)             │
│  - Repository interfaces                │
│  - Use cases / Services                 │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer                      │
│  (Implementation)                       │
│  - Repository implementations           │
│  - Data sources (Watch, Supabase)       │
└─────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── core/
│   └── providers/              # All Riverpod providers
│       ├── data_sources/       # Data source providers
│       ├── repositories/       # Repository providers
│       ├── services/           # Service/use case providers
│       └── state/              # UI state providers
│
├── domain/                     # Business logic (framework-independent)
│   ├── entities/               # Core data models
│   └── repositories/           # Repository interfaces
│
├── data/                       # Data layer implementations
│   └── repositories/           # Repository implementations
│
├── services/                   # External services (Watch, Supabase)
│
└── screens/                    # UI screens (ConsumerWidget)
```

## Key Components

### 1. Entities (Domain Layer)

Pure Dart classes representing business models:

```dart
// lib/domain/entities/heart_rate_data.dart
class HeartRateData {
  final int? bpm;
  final List<int> ibiValues;
  final DateTime timestamp;
  final HeartRateStatus status;
}
```

### 2. Repository Interfaces (Domain Layer)

Define contracts for data operations:

```dart
// lib/domain/repositories/heart_rate_repository.dart
abstract class HeartRateRepository {
  Stream<HeartRateData> get heartRateStream;
  Future<void> startTracking();
  Future<void> stopTracking();
}
```

### 3. Repository Implementations (Data Layer)

Implement the interfaces using data sources:

```dart
// lib/data/repositories/heart_rate_repository_impl.dart
class HeartRateRepositoryImpl implements HeartRateRepository {
  final WatchBridge _watchBridge;
  final SupabaseService _supabaseService;
  
  @override
  Stream<HeartRateData> get heartRateStream {
    return _watchBridge.heartRateStream.map((data) {
      return HeartRateData.fromJson(data);
    });
  }
}
```

### 4. Providers (Provider Layer)

Wire everything together with Riverpod:

```dart
// lib/core/providers/repositories/heart_rate_repository_provider.dart
final heartRateRepositoryProvider = Provider<HeartRateRepository>((ref) {
  final watchBridge = ref.watch(watchDataSourceProvider);
  final supabaseService = ref.watch(supabaseDataSourceProvider);
  
  return HeartRateRepositoryImpl(
    watchBridge: watchBridge,
    supabaseService: supabaseService,
  );
});
```

### 5. State Providers (Provider Layer)

Manage UI state:

```dart
// lib/core/providers/state/heart_rate_state_provider.dart
final currentHeartRateProvider = StreamProvider<HeartRateData>((ref) {
  final repository = ref.watch(heartRateRepositoryProvider);
  return repository.heartRateStream;
});
```

### 6. UI Screens (Presentation Layer)

Use ConsumerWidget to watch providers:

```dart
class HeartRateMonitorScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(currentHeartRateProvider);
    
    return heartRateAsync.when(
      data: (heartRateData) => Text('${heartRateData.bpm} BPM'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Usage Examples

### Starting Heart Rate Tracking

```dart
// In your widget
ElevatedButton(
  onPressed: () {
    ref.read(heartRateTrackingStateProvider.notifier).startTracking();
  },
  child: Text('Start'),
)
```

### Watching Heart Rate Data

```dart
// In your ConsumerWidget
final heartRateAsync = ref.watch(currentHeartRateProvider);

heartRateAsync.when(
  data: (data) => Text('${data.bpm} BPM'),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
);
```

### Checking Connection Status

```dart
final connectionAsync = ref.watch(watchConnectionStateProvider);

connectionAsync.when(
  data: (isConnected) => Icon(
    isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
  ),
  loading: () => CircularProgressIndicator(),
  error: (_, __) => Icon(Icons.error),
);
```

## Benefits

1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Clear separation makes code easier to understand
3. **Scalability**: Easy to add new features without breaking existing code
4. **Flexibility**: Can swap implementations without changing business logic
5. **Type Safety**: Compile-time checks with Riverpod

## Adding New Features

To add a new feature (e.g., Activity Tracking):

1. Create entity: `lib/domain/entities/activity_data.dart`
2. Create repository interface: `lib/domain/repositories/activity_repository.dart`
3. Create implementation: `lib/data/repositories/activity_repository_impl.dart`
4. Create provider: `lib/core/providers/repositories/activity_repository_provider.dart`
5. Create state provider: `lib/core/providers/state/activity_state_provider.dart`
6. Use in UI: `ref.watch(activityStateProvider)`

## Next Steps

- [ ] Add error handling with Either/Result types
- [ ] Implement use cases for complex business logic
- [ ] Add caching layer for offline support
- [ ] Create integration tests for repositories
- [ ] Add logging and analytics
