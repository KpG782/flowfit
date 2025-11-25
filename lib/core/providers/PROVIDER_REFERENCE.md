# Provider Quick Reference

## Available Providers

### Data Sources
```dart
watchDataSourceProvider        // WatchBridge instance
supabaseDataSourceProvider     // SupabaseService instance
```

### Repositories
```dart
heartRateRepositoryProvider    // Heart rate data operations
activityRepositoryProvider     // Activity data (placeholder)
sleepRepositoryProvider        // Sleep data (placeholder)
```

### Services
```dart
heartRateServiceProvider       // Heart rate use cases
```

### State Providers
```dart
currentHeartRateProvider              // Stream<HeartRateData>
heartRateTrackingStateProvider        // bool (is tracking)
watchConnectionStateProvider          // Stream<bool> (is connected)
connectionControlProvider             // ConnectionState enum
```

## Common Usage Patterns

### Read Once (No Rebuild)
```dart
final value = ref.read(providerName);
```

### Watch (Rebuild on Change)
```dart
final value = ref.watch(providerName);
```

### Listen (Side Effects)
```dart
ref.listen(providerName, (previous, next) {
  // Handle change
});
```

### Call Methods on Notifier
```dart
ref.read(heartRateTrackingStateProvider.notifier).startTracking();
ref.read(connectionControlProvider.notifier).connect();
```

### Handle Async Data
```dart
final asyncValue = ref.watch(currentHeartRateProvider);

asyncValue.when(
  data: (data) => Text('Data: $data'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);

// Or use pattern matching
asyncValue.maybeWhen(
  data: (data) => Text('Data: $data'),
  orElse: () => Text('Loading...'),
);
```

## Widget Types

### ConsumerWidget
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(someProvider);
    return Text('$data');
  }
}
```

### ConsumerStatefulWidget
```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(someProvider);
    return Text('$data');
  }
}
```

### Consumer (Widget)
```dart
Consumer(
  builder: (context, ref, child) {
    final data = ref.watch(someProvider);
    return Text('$data');
  },
)
```
