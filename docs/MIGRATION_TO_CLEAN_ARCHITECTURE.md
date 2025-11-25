# Migration Guide: Clean Architecture with Riverpod

## Overview

This guide helps you migrate existing FlowFit screens to use the new clean architecture with Riverpod.

## Before & After Examples

### Example 1: Heart Rate Display

#### Before (Old Approach)
```dart
class HeartRateScreen extends StatefulWidget {
  @override
  _HeartRateScreenState createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  final WatchBridge _watchBridge = WatchBridge();
  int? _currentBpm;
  
  @override
  void initState() {
    super.initState();
    _watchBridge.heartRateStream.listen((data) {
      setState(() {
        _currentBpm = data['bpm'];
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('${_currentBpm ?? '--'} BPM');
  }
}
```

#### After (Clean Architecture)
```dart
class HeartRateScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(currentHeartRateProvider);
    
    return heartRateAsync.when(
      data: (heartRate) => Text('${heartRate.bpm ?? '--'} BPM'),
      loading: () => CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}
```

### Example 2: Starting/Stopping Tracking

#### Before
```dart
ElevatedButton(
  onPressed: () async {
    await WatchBridge().startHeartRateTracking();
    setState(() {
      _isTracking = true;
    });
  },
  child: Text('Start'),
)
```

#### After
```dart
ElevatedButton(
  onPressed: () {
    ref.read(heartRateTrackingStateProvider.notifier).startTracking();
  },
  child: Text('Start'),
)
```

## Migration Steps

### Step 1: Update Widget Type

Change from `StatefulWidget` to `ConsumerWidget`:

```dart
// Before
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// After
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
```

### Step 2: Replace Direct Service Calls

Replace direct service instantiation with providers:

```dart
// Before
final watchBridge = WatchBridge();
watchBridge.startHeartRateTracking();

// After
ref.read(heartRateTrackingStateProvider.notifier).startTracking();
```

### Step 3: Replace setState with Providers

Remove manual state management:

```dart
// Before
int? _currentBpm;

void _updateBpm(int bpm) {
  setState(() {
    _currentBpm = bpm;
  });
}

// After
final heartRateAsync = ref.watch(currentHeartRateProvider);
// State is automatically managed
```

### Step 4: Handle Async Data

Use `.when()` for async providers:

```dart
final asyncData = ref.watch(someStreamProvider);

asyncData.when(
  data: (data) => Text('Data: $data'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## Common Patterns

### Pattern 1: Display Real-Time Data

```dart
class LiveDataWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(currentHeartRateProvider);
    
    return dataAsync.maybeWhen(
      data: (data) => Text('${data.bpm} BPM'),
      orElse: () => Text('--'),
    );
  }
}
```

### Pattern 2: Button Actions

```dart
ElevatedButton(
  onPressed: () {
    ref.read(heartRateTrackingStateProvider.notifier).startTracking();
  },
  child: Text('Start'),
)
```

### Pattern 3: Conditional UI Based on State

```dart
final isTracking = ref.watch(heartRateTrackingStateProvider);

if (isTracking) {
  return StopButton();
} else {
  return StartButton();
}
```

### Pattern 4: Side Effects (Navigation, Snackbars)

```dart
ref.listen(heartRateTrackingStateProvider, (previous, next) {
  if (next == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tracking started')),
    );
  }
});
```

## Screens to Migrate

### Priority 1 (Heart Rate Related)
- [ ] `lib/screens/phone_home.dart` - Main phone screen
- [ ] `lib/screens/wear/wear_dashboard.dart` - Watch dashboard

### Priority 2 (Other Features)
- [ ] `lib/screens/dashboard.dart` - Main dashboard
- [ ] `lib/screens/workout/activity_tracker.dart` - Activity tracking
- [ ] `lib/screens/sleep/sleep_mode.dart` - Sleep tracking

### Priority 3 (Supporting Screens)
- [ ] `lib/screens/workout/workout_library.dart`
- [ ] `lib/screens/nutrition/food_logger.dart`

## Testing the Migration

After migrating a screen:

1. **Verify it compiles**: `flutter analyze`
2. **Test functionality**: Run the app and test all features
3. **Check for memory leaks**: Ensure providers are properly disposed
4. **Verify state persistence**: Check that state survives widget rebuilds

## Troubleshooting

### Issue: "ProviderScope not found"
**Solution**: Ensure `main.dart` wraps the app with `ProviderScope`:
```dart
void main() {
  runApp(
    const ProviderScope(
      child: FlowFitPhoneApp(),
    ),
  );
}
```

### Issue: "Cannot read provider outside build method"
**Solution**: Use `ref.read()` for one-time reads in callbacks:
```dart
onPressed: () {
  ref.read(someProvider.notifier).doSomething();
}
```

### Issue: "Widget rebuilds too often"
**Solution**: Use `ref.watch()` only for data you need to display. Use `ref.read()` for actions.

## Benefits After Migration

✅ Less boilerplate code
✅ Automatic state management
✅ Better error handling
✅ Easier testing
✅ Type-safe state access
✅ No manual dispose needed
✅ Reactive UI updates
