# Samsung Health Sensor Implementation Checklist

## ✅ Already Completed

- [x] Samsung Health Sensor SDK AAR file added
- [x] Android permissions configured in AndroidManifest.xml
- [x] Method Channel and Event Channel set up
- [x] WatchBridgeService (Flutter) implemented
- [x] HealthTrackingManager (Kotlin) implemented
- [x] MainActivity (Kotlin) updated with full implementation
- [x] HeartRateData model updated with IBI support
- [x] Kotlin coroutines dependency added
- [x] Error handling and logging implemented

## 🔧 Before You Start Testing

### 1. Build the Project
```bash
cd android
./gradlew clean
./gradlew build
cd ..
```

### 2. Check Device Requirements
- [ ] Galaxy Watch4 or higher
- [ ] Watch is paired and connected
- [ ] Samsung Health app is installed on watch
- [ ] Watch is charged (>20% battery)

### 3. Deploy to Watch
```bash
# List connected devices
flutter devices

# Run on watch
flutter run -d <watch-device-id>
```

## 📝 Testing Steps

### Step 1: Permission Check
```dart
final watchBridge = WatchBridgeService();
final status = await watchBridge.checkBodySensorPermission();
print('Permission status: $status');
```

Expected: `PermissionStatus.notDetermined` or `PermissionStatus.granted`

### Step 2: Request Permission
```dart
final granted = await watchBridge.requestBodySensorPermission();
print('Permission granted: $granted');
```

Expected: Permission dialog appears, user grants permission

### Step 3: Connect to Service
```dart
final connected = await watchBridge.connectToWatch();
print('Connected: $connected');
```

Expected: `true` (connection successful)

### Step 4: Start Tracking
```dart
final started = await watchBridge.startHeartRateTracking();
print('Tracking started: $started');
```

Expected: `true` (tracking started)

### Step 5: Receive Data
```dart
watchBridge.heartRateStream.listen((data) {
  print('HR: ${data.bpm} bpm');
  print('IBI: ${data.ibiValues}');
  print('Status: ${data.status}');
});
```

Expected: Heart rate data every 1-2 seconds

### Step 6: Stop Tracking
```dart
await watchBridge.stopHeartRateTracking();
await watchBridge.disconnectFromWatch();
```

Expected: Tracking stops, no more data

## 🐛 Debugging

### Check Logcat
```bash
# Filter for health-related logs
adb logcat | grep -i "health\|MainActivity\|HealthTrackingManager"

# Or specific tags
adb logcat MainActivity:D HealthTrackingManager:D *:S
```

### Common Issues

**Issue: "Health tracking manager not initialized"**
- Solution: Restart the app, check MainActivity.onCreate()

**Issue: "Not connected to Health Tracking Service"**
- Solution: Call `connectToWatch()` before `startHeartRateTracking()`

**Issue: "Permission denied"**
- Solution: Check Settings → Apps → FlowFit → Permissions

**Issue: "Sensor not supported"**
- Solution: Device doesn't support continuous HR tracking (need Watch4+)

**Issue: No data received**
- Solution: Wear watch on wrist, ensure good skin contact

## 🎯 Integration Points

### Update Your UI

**wear_dashboard.dart**
```dart
// Add heart rate display
StreamBuilder<HeartRateData>(
  stream: watchBridge.heartRateStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('${snapshot.data!.bpm} BPM');
    }
    return Text('--');
  },
)
```

**activity_tracker.dart**
```dart
// Start tracking when workout begins
await watchBridge.connectToWatch();
await watchBridge.startHeartRateTracking();

// Stop when workout ends
await watchBridge.stopHeartRateTracking();
```

### Save to Supabase

```dart
watchBridge.heartRateStream.listen((data) async {
  if (data.bpm != null) {
    await supabaseService.insertHeartRate(
      bpm: data.bpm!,
      timestamp: data.timestamp,
      ibiValues: data.ibiValues,
    );
  }
});
```

## 📊 Data Analysis

### Heart Rate Zones
```dart
String getHeartRateZone(int bpm) {
  if (bpm < 100) return 'Resting';
  if (bpm < 120) return 'Light';
  if (bpm < 140) return 'Moderate';
  if (bpm < 160) return 'Hard';
  return 'Maximum';
}
```

### Heart Rate Variability (HRV)
```dart
double calculateHRV(List<int> ibiValues) {
  if (ibiValues.length < 2) return 0;
  
  // Calculate RMSSD (Root Mean Square of Successive Differences)
  double sumSquaredDiffs = 0;
  for (int i = 1; i < ibiValues.length; i++) {
    double diff = (ibiValues[i] - ibiValues[i-1]).toDouble();
    sumSquaredDiffs += diff * diff;
  }
  
  return sqrt(sumSquaredDiffs / (ibiValues.length - 1));
}
```

## 🚀 Next Features

- [ ] Background heart rate monitoring
- [ ] Heart rate alerts (too high/low)
- [ ] Workout heart rate zones
- [ ] HRV tracking and trends
- [ ] Resting heart rate calculation
- [ ] Heart rate recovery after exercise
- [ ] Integration with sleep tracking

## 📚 Reference

- **Samsung Health Sensor SDK**: Provides heart rate data
- **HealthTrackingService**: System service for sensor access
- **HealthTracker**: Manages individual sensor tracking
- **DataPoint**: Contains sensor readings (HR + IBI)
- **ValueKey**: Keys for extracting values from DataPoint

## ✨ Tips

1. **Wear the watch properly** - Snug fit, sensor on wrist bone
2. **Wait for stabilization** - First readings may be inaccurate
3. **Handle null BPM** - During measurement, bpm can be null
4. **Use IBI for HRV** - More accurate than just BPM
5. **Test on real device** - Emulator doesn't support sensors
6. **Check battery impact** - Continuous tracking drains battery
7. **Implement foreground service** - For background tracking
