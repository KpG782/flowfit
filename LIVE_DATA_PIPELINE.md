# Pulsify: Live Data Pipeline — Watch to Phone to AI Classifier

> Complete reference for how real-time sensor data flows from the Samsung Galaxy Watch,
> through the native Kotlin bridge, into Flutter, and finally into the TFLite AI activity
> classifier. Use this as a template for any Flutter + Kotlin native bridge project.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Layer 1 — Watch: Samsung Health SDK + Accelerometer](#2-layer-1--watch-samsung-health-sdk--accelerometer)
3. [Layer 2 — Watch-to-Phone Transport: Wearable Data Layer API](#3-layer-2--watch-to-phone-transport-wearable-data-layer-api)
4. [Layer 3 — Phone: WearableListenerService receives from Watch](#4-layer-3--phone-wearablelistenerservice-receives-from-watch)
5. [Layer 4 — Kotlin-to-Flutter Bridge: MethodChannel + EventChannel](#5-layer-4--kotlin-to-flutter-bridge-methodchannel--eventchannel)
6. [Layer 5 — Flutter: WatchBridgeService + SensorBatch model](#6-layer-5--flutter-watchbridgeservice--sensorbatch-model)
7. [Layer 6 — AI Classifier: TFLite Inference Pipeline](#7-layer-6--ai-classifier-tflite-inference-pipeline)
8. [Channel Registry — All Channel Names and Message Paths](#8-channel-registry--all-channel-names-and-message-paths)
9. [Data Shapes and JSON Contracts](#9-data-shapes-and-json-contracts)
10. [AndroidManifest.xml Requirements](#10-androidmanifestxml-requirements)
11. [Permissions Required](#11-permissions-required)
12. [Common Issues and How to Fix Them](#12-common-issues-and-how-to-fix-them)
13. [Lifecycle and Threading Rules](#13-lifecycle-and-threading-rules)
14. [Checklist: Adapting This Pattern to Another Project](#14-checklist-adapting-this-pattern-to-another-project)

---

## 1. Architecture Overview

```
[Samsung Galaxy Watch]
        |
  Samsung Health SDK (HealthTrackingService)
  Android SensorManager (Accelerometer)
        |
  WatchSensorService.kt         <- buffers 32 accel samples + HR
  HealthTrackingManager.kt      <- HR validation + IBI extraction
        |
  Wearable MessageClient        <- Google Wear OS Data Layer
  (message path: /sensor_data)
        |
[Android Phone]
        |
  PhoneDataListenerService.kt   <- WearableListenerService, always running
  (extends WearableListenerService)
        |
  EventChannel (Kotlin -> Flutter)
  ("com.pulsify.phone/sensor_data")
        |
[Flutter / Dart]
        |
  WatchBridgeService.dart       <- wraps all channels
  SensorBatch.fromJson()        <- parses JSON, builds [accX, accY, accZ, bpm]
        |
  ClassifyActivityUseCase       <- REST gate (BPM < 85 = Calm, skip model)
        |
  TFLiteActivityClassifier      <- runs assets/model/activity_tracker.tflite
  Input:  [1, 320, 4]           <- 320 samples x [accX, accY, accZ, bpm]
  Output: [1, 3]                <- [Stress%, Cardio%, Strength%]
        |
  ActivityClassifierViewModel   <- ChangeNotifier, drives UI
```

---

## 2. Layer 1 — Watch: Samsung Health SDK + Accelerometer

### Files
- `android/app/src/main/kotlin/com/example/Pulsify/HealthTrackingManager.kt`
- `android/app/src/main/kotlin/com/example/Pulsify/WatchSensorService.kt`
- `android/app/src/main/kotlin/com/example/Pulsify/TrackedData.kt`

### How it works

#### Heart Rate (Samsung Health SDK)

```kotlin
// 1. Create service and connect (MUST use applicationContext, not activity context)
healthTrackingService = HealthTrackingService(connectionListener, appContext)
healthTrackingService?.connectService()

// 2. Wait for ConnectionListener.onConnectionSuccess() callback
// 3. Check capability AFTER connection, not before
val supported = service.trackingCapability.supportHealthTrackerTypes
    .contains(HealthTrackerType.HEART_RATE_CONTINUOUS)

// 4. Get tracker and attach listener
heartRateTracker = service.getHealthTracker(HealthTrackerType.HEART_RATE_CONTINUOUS)
heartRateTracker?.setEventListener(trackerEventListener)

// 5. In TrackerEventListener.onDataReceived():
val hrValue  = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE) as? Int
val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS) as? Int
val ibiList  = dataPoint.getValue(ValueKey.HeartRateSet.IBI_LIST) as? IntArray
val ibiStatuses = dataPoint.getValue(ValueKey.HeartRateSet.IBI_STATUS_LIST) as? IntArray

// Valid HR: status == 1
// Valid IBI: ibiStatuses[i] == 0 AND ibiValues[i] != 0
```

#### Accelerometer

```kotlin
// Registered at SENSOR_DELAY_GAME (~50Hz, close to target 32Hz)
sensorManager.registerListener(accelListener, accelerometer, SensorManager.SENSOR_DELAY_GAME)

// Buffer 32 samples, then transmit when buffer full AND 1000ms have passed
private const val BUFFER_SIZE = 32
private const val MIN_TRANSMISSION_INTERVAL_MS = 1000L
```

#### Critical Design Decisions

- **Always use `applicationContext`** for `HealthTrackingService`, never the Activity context.
  If you use the Activity context, the service dies when the screen turns off.
- HR tracking and accelerometer tracking are **started/stopped together** in `startTracking()` / `stopTracking()`.
- `sensorService.currentHeartRate = hrValue` — the latest HR is injected into each accelerometer
  batch so the phone gets synchronized [accX, accY, accZ, bpm] data.
- HR data validation: only `HR_STATUS_VALID == 1` readings are stored in `validHrData` for batch
  transmission. Invalid readings are still forwarded to Flutter for real-time display.
- `validHrData` is capped at `MAX_DATA_POINTS = 40` (oldest entries dropped when full).

---

## 3. Layer 2 — Watch-to-Phone Transport: Wearable Data Layer API

### Files
- `android/app/src/main/kotlin/com/example/Pulsify/WatchToPhoneSyncManager.kt`
- `android/app/src/main/kotlin/com/example/Pulsify/WatchSensorService.kt` (sendBatchToPhone)

### Message paths used

| Path               | Content                              | Sender     |
|--------------------|--------------------------------------|------------|
| `/heart_rate`      | Single HR JSON (HeartRateData)       | Watch      |
| `/heart_rate_batch`| Array of TrackedData JSON            | Watch      |
| `/sensor_data`     | SensorBatch JSON (accel + bpm)       | Watch      |

### How node discovery works

```kotlin
// Step 1: Try capability-based discovery (preferred)
capabilityClient.getCapability("pulsify_phone_app", CapabilityClient.FILTER_REACHABLE).await()

// Step 2: Fallback to all connected nodes
nodeClient.connectedNodes.await()

// Step 3: Send to first reachable node
messageClient.sendMessage(node.id, MESSAGE_PATH, jsonData.toByteArray()).await()
```

### Phone capability declaration (required on phone side)

The phone app must declare a `wear.xml` capability file so the watch can find it:

```xml
<!-- android/app/src/main/res/xml/wear.xml -->
<wearableApp package="com.example.pulsify">
    <versionCode>1</versionCode>
    <versionName>1.0</versionName>
    <capabilities>
        <capability name="pulsify_phone_app" />
    </capabilities>
</wearableApp>
```

And referenced in `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.wearable.app"
    android:resource="@xml/wear" />
```

### Common transport issues

- **No connected nodes**: Bluetooth not paired, or Pulsify not installed on the phone.
- **Capability not found, falls back to nodeClient**: `wear.xml` missing or not referenced in manifest.
- **Message send fails silently**: `addOnFailureListener` fires but no exception is thrown to Dart.
  Always log failures in the listener callbacks.
- **Data race on accelBuffer**: The buffer is synchronized with `synchronized(accelBuffer)`.
  Do not access it from multiple threads without the lock.

---

## 4. Layer 3 — Phone: WearableListenerService receives from Watch

### File
- `android/app/src/main/kotlin/com/example/Pulsify/PhoneDataListenerService.kt`

### How it works

```kotlin
class PhoneDataListenerService : WearableListenerService() {

    companion object {
        // Static sinks set by MainActivity when Flutter engine is ready
        var eventSink: EventChannel.EventSink? = null
        var sensorBatchEventSink: EventChannel.EventSink? = null
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            "/heart_rate"       -> handleHeartRateData(messageEvent)
            "/heart_rate_batch" -> handleBatchData(messageEvent)
            "/sensor_data"      -> handleSensorBatchData(messageEvent)
        }
    }
}
```

After receiving a message:
1. Deserialize bytes to UTF-8 JSON string.
2. Parse `JSONObject` to `Map<String, Any?>` (recursive for nested arrays).
3. Post to **main thread** via `mainHandler.post { sensorBatchEventSink?.success(jsonMap) }`.
4. If the Flutter engine is not running (`eventSink == null`), launch `MainActivity` with the raw
   JSON as an Intent extra.

### Critical rules

- `WearableListenerService` runs in its **own background process**. It does NOT share the same
  Flutter engine instance. The event sinks are static (`companion object`) so `MainActivity` can
  wire them when it initializes the Flutter engine.
- Always post to main thread before calling `eventSink?.success()` — EventChannel is not
  thread-safe.
- Declare the service in `AndroidManifest.xml` with the correct intent-filter and path prefixes
  (see Section 10).

---

## 5. Layer 4 — Kotlin-to-Flutter Bridge: MethodChannel + EventChannel

### File
- `android/app/src/main/kotlin/com/example/Pulsify/MainActivity.kt`

### Channel setup (inside `configureFlutterEngine`)

```kotlin
// ---- METHOD CHANNELS ----

// Watch sensor control (start/stop HR, connect, permissions)
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.watch/data")
    .setMethodCallHandler { call, result -> ... }

// Watch-to-phone sync (manual send)
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.watch/sync")
    .setMethodCallHandler { call, result -> ... }

// Phone-side listener control
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.phone/data")
    .setMethodCallHandler { call, result -> ... }

// Geofence control
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.geofence/native")
    .setMethodCallHandler { call, result -> ... }

// ---- EVENT CHANNELS ----

// Real-time HR stream from watch sensors
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.watch/heartrate")
    .setStreamHandler(...)  // sets heartRateEventSink

// Sensor batch transmission notification (watch side)
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.watch/transmission")
    .setStreamHandler(...)  // sets transmissionEventSink

// HR data received from watch (phone side)
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.phone/heartrate")
    .setStreamHandler(...)  // sets PhoneDataListenerService.eventSink

// Sensor batch received from watch (phone side) -> goes to AI classifier
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.phone/sensor_data")
    .setStreamHandler(...)  // sets PhoneDataListenerService.sensorBatchEventSink

// Geofence events
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.geofence/events")
    .setStreamHandler(...)
```

### How data gets from native to Flutter (EventChannel pattern)

```kotlin
// Native side: push data
mainHandler.post {
    heartRateEventSink?.success(mapOf(
        "bpm"       to data.bpm,
        "ibiValues" to data.ibiValues,
        "timestamp" to data.timestamp,
        "status"    to data.status
    ))
}
```

```dart
// Flutter side: receive as Stream
EventChannel('com.pulsify.watch/heartrate')
    .receiveBroadcastStream()
    .map((event) => HeartRateData.fromJson(Map<String, dynamic>.from(event as Map)))
    .listen((hr) { ... });
```

### Wake lock pattern

```kotlin
// Acquire on startHeartRate() — keeps CPU awake when screen turns off
wakeLock?.acquire(10 * 60 * 1000L)  // 10 minute timeout

// Release on stopHeartRate() / onDestroy()
wakeLock?.release()
```

Manifest permission required:
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

---

## 6. Layer 5 — Flutter: WatchBridgeService + SensorBatch model

### Files
- `lib/services/watch_bridge.dart`
- `lib/models/sensor_batch.dart`
- `lib/models/heart_rate_data.dart`

### WatchBridgeService channel declarations

```dart
static const MethodChannel _methodChannel = MethodChannel('com.pulsify.watch/data');
static const MethodChannel _syncChannel   = MethodChannel('com.pulsify.watch/sync');
static const EventChannel  _heartRateEventChannel = EventChannel('com.pulsify.watch/heartrate');
```

### Startup sequence (must follow this order)

```dart
final bridge = WatchBridgeService();

// 1. Request permissions (native dialog)
await bridge.requestPermission();

// 2. Connect to Samsung Health service
await bridge.connectToWatch();  // has exponential backoff retry (3x, 500ms base)

// 3. Start tracking
await bridge.startHeartRateTracking();

// 4. Subscribe to stream
bridge.heartRateStream.listen((hr) {
    // hr.bpm, hr.ibiValues, hr.timestamp, hr.status
    // Auto-sync to phone is triggered here via _autoSyncToPhone()
});
```

### SensorBatch JSON parsing

The watch sends this JSON via `/sensor_data`:

```json
{
    "type":        "sensor_batch",
    "timestamp":   1712345678000,
    "bpm":         82,
    "sampleRate":  32,
    "count":       32,
    "accelerometer": [
        [0.12, -0.45, 9.81],
        [0.15, -0.42, 9.79],
        ...
    ]
}
```

`SensorBatch.fromJson()` converts this into 4-feature vectors:

```dart
// Each sample: [accX, accY, accZ, bpm]
// bpm is broadcast to all 32 samples (same value)
final samples = accelData.map((xyz) => [
    (xyz[0] as num).toDouble(),
    (xyz[1] as num).toDouble(),
    (xyz[2] as num).toDouble(),
    bpm,
]).toList();
```

### Retry / error handling in WatchBridgeService

- `connectToWatch()` uses `_retryWithExponentialBackoff`: max 3 retries, starting at 500ms, doubling.
- Retryable error codes: `CONNECTION_FAILED`, `TIMEOUT`, `SERVICE_UNAVAILABLE`.
- Non-retryable: `PERMISSION_DENIED`, `SENSOR_NOT_SUPPORTED`, unknown errors.
- All `PlatformException` codes map to typed `SensorError` objects with `SensorErrorCode` enum.
- All operations have a `Duration(seconds: 10)` timeout to prevent indefinite hangs.

---

## 7. Layer 6 — AI Classifier: TFLite Inference Pipeline

### Files
- `lib/features/activity_classifier/platform/tflite_activity_classifier.dart`
- `lib/features/activity_classifier/data/tflite_activity_repository.dart`
- `lib/features/activity_classifier/domain/classify_activity_usecase.dart`
- `lib/features/activity_classifier/domain/activity.dart`
- `lib/features/activity_classifier/data/activity_dto.dart`
- `lib/features/activity_classifier/presentation/providers.dart`
- `lib/features/activity_classifier/platform/heart_bpm_adapter.dart`

### Clean Architecture layers

```
Presentation  ->  ActivityClassifierViewModel (ChangeNotifier)
Domain        ->  ClassifyActivityUseCase
                  ActivityClassifierRepository (abstract interface)
Data          ->  TFLiteActivityRepository (implements interface)
Platform      ->  TFLiteActivityClassifier (wraps tflite_flutter)
```

### Model specification

| Property      | Value                              |
|---------------|------------------------------------|
| Model file    | `assets/model/activity_tracker.tflite` |
| Input shape   | `[1, 320, 4]`                      |
| Input meaning | batch=1, 320 time steps, 4 features|
| Features      | `[accX, accY, accZ, bpm]`          |
| Output shape  | `[1, 3]`                           |
| Output labels | `[Stress%, Cardio%, Strength%]`    |

### Inference flow

```dart
// Step 1: Load model once at startup
await classifier.loadModel();  // validates input/output shapes

// Step 2: Validate shapes match expectations
// Input:  [1, 320, 4]
// Output: [1, 3]

// Step 3: Classify (called from use case)
final input  = [buffer];  // shape: [1, 320, 4]
final output = List.filled(3, 0.0).reshape([1, 3]);
_interpreter!.run(input, output);
final probabilities = List<double>.from(output[0] as List);
// e.g. [0.12, 0.73, 0.15] -> Cardio wins

// Step 4: Map to label (in ActivityDto)
int maxIndex = probabilities.indexOf(probabilities.reduce(max));
// labels[maxIndex] -> "Cardio"
```

### REST gate in ClassifyActivityUseCase

Before invoking the TFLite model, a threshold check runs:

```dart
// If BPM < 85 -> user is at rest, skip model entirely
final lastBpm = buffer.last[3];  // index 3 = bpm
if (lastBpm < 85.0) {
    return Activity(label: 'Calm', confidence: 0.0, ...);
}
// Otherwise delegate to TFLite
return _repository.classifyActivity(buffer);
```

**Why**: The model is trained for active/stressed states only. Running it at rest produces
meaningless results and wastes CPU.

### Buffer accumulation (not implemented in the repo — you must implement this)

The watch sends 32-sample batches every ~1 second. The model needs 320 samples.
You need a **sliding window buffer** on the Flutter side:

```dart
final List<List<double>> _window = [];

void onSensorBatch(SensorBatch batch) {
    _window.addAll(batch.samples);

    // Keep only the last 320 samples
    if (_window.length > 320) {
        _window.removeRange(0, _window.length - 320);
    }

    // Run inference when window is full
    if (_window.length == 320) {
        viewModel.classify(List.from(_window));
    }
}
```

### Provider setup (MultiProvider / Riverpod pattern)

```dart
// With provider package:
MultiProvider(
  providers: [
    Provider<TFLiteActivityClassifier>(
        create: (_) => TFLiteActivityClassifier()),
    ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
        update: (_, classifier, __) => TFLiteActivityRepository(classifier)),
    ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
        update: (_, repo, __) => ClassifyActivityUseCase(repo)),
    ChangeNotifierProxyProvider<ClassifyActivityUseCase, ActivityClassifierViewModel>(
        update: (_, useCase, __) => ActivityClassifierViewModel(useCase)),
  ],
)

// With Riverpod:
final watchDataSourceProvider = Provider((_) => WatchBridgeService());
```

### HeartBpmAdapter — connecting external BPM streams

```dart
final adapter = HeartBpmAdapter();

// Connect a stream from any source (plugin, watch bridge, etc.)
adapter.connectExternalStream(myBpmStream);

// Or inject a manual value for testing
adapter.setManualBpm(75);

// Consume
adapter.bpmStream.listen((bpm) { ... });
```

---

## 8. Channel Registry — All Channel Names and Message Paths

### MethodChannels

| Channel Name                  | Methods                                                      | Direction      |
|-------------------------------|--------------------------------------------------------------|----------------|
| `com.pulsify.watch/data`      | `requestPermission`, `checkPermission`, `connectWatch`,      | Flutter->Native |
|                               | `disconnectWatch`, `isWatchConnected`, `startHeartRate`,     |                |
|                               | `stopHeartRate`, `getCurrentHeartRate`, `getTestModeData`    |                |
| `com.pulsify.watch/sync`      | `sendHeartRateToPhone`, `sendBatchToPhone`,                  | Flutter->Native |
|                               | `checkPhoneConnection`, `getConnectedNodesCount`             |                |
| `com.pulsify.phone/data`      | `startListening`, `stopListening`, `isWatchConnected`        | Flutter->Native |
| `com.pulsify.geofence/native` | `registerGeofence`, `unregisterGeofence`                     | Flutter->Native |

### EventChannels

| Channel Name                    | Payload type           | Direction      | Notes                            |
|---------------------------------|------------------------|----------------|----------------------------------|
| `com.pulsify.watch/heartrate`   | `Map<String, dynamic>` | Native->Flutter | Real-time HR from watch sensors  |
| `com.pulsify.watch/transmission`| `Map<String, dynamic>` | Native->Flutter | Fires when a batch was transmitted|
| `com.pulsify.phone/heartrate`   | `Map<String, dynamic>` | Native->Flutter | HR received by phone from watch  |
| `com.pulsify.phone/sensor_data` | `Map<String, dynamic>` | Native->Flutter | Accel+HR batch for AI classifier |
| `com.pulsify.geofence/events`   | `Map<String, dynamic>` | Native->Flutter | Geofence enter/exit events       |

### Wearable Message Paths

| Path               | Content                        | From    | To    |
|--------------------|--------------------------------|---------|-------|
| `/heart_rate`      | JSON: HeartRateData            | Watch   | Phone |
| `/heart_rate_batch`| JSON array: TrackedData[]      | Watch   | Phone |
| `/sensor_data`     | JSON: SensorBatch              | Watch   | Phone |

---

## 9. Data Shapes and JSON Contracts

### HeartRateData (Kotlin -> Flutter, EventChannel map)

```json
{
    "bpm":       82,
    "ibiValues": [735, 742, 728],
    "timestamp": 1712345678000,
    "status":    "active"
}
```

- `status`: `"active"` (HR_STATUS == 1) or `"inactive"`.
- `ibiValues`: inter-beat intervals in milliseconds, empty if none valid.

### TrackedData (batch HR, for sendBatchToPhone)

```json
[
    { "hr": 82, "ibi": [735, 742] },
    { "hr": 84, "ibi": [714, 718] }
]
```

### SensorBatch (from watch /sensor_data, the main AI input)

```json
{
    "type":       "sensor_batch",
    "timestamp":  1712345678000,
    "bpm":        82,
    "sampleRate": 32,
    "count":      32,
    "accelerometer": [
        [0.12, -0.45, 9.81],
        [0.15, -0.42, 9.79]
    ]
}
```

After `SensorBatch.fromJson()`, each sample becomes:
```
[accX, accY, accZ, bpm] = [0.12, -0.45, 9.81, 82.0]
```

### AI Model Input/Output

```
Input:  List<List<double>>  shape [320][4]   -> flatten to [1][320][4] for tflite
Output: List<double>        shape [3]        -> [Stress%, Cardio%, Strength%]
```

Activity labels by index:
```
0 -> "Stress"
1 -> "Cardio"
2 -> "Strength"
(+ "Calm" from REST gate, never touches the model)
```

---

## 10. AndroidManifest.xml Requirements

### Watch-side (wear app) manifest

```xml
<!-- Required features -->
<uses-feature android:name="android.hardware.type.watch" />

<!-- Permissions -->
<uses-permission android:name="android.permission.BODY_SENSORS" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" /> <!-- Android 15+ -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />

<application>
    <!-- Standalone watch app -->
    <meta-data
        android:name="com.google.android.wearable.standalone"
        android:value="true" />

    <!-- Wear OS library (optional but recommended) -->
    <uses-library
        android:name="com.google.android.wearable"
        android:required="false" />

    <!-- Disable Impeller if you hit gralloc4 format errors -->
    <meta-data
        android:name="io.flutter.embedding.android.EnableImpeller"
        android:value="false" />

    <!-- MainActivity -->
    <activity
        android:name=".MainActivity"
        android:launchMode="singleTop"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity>

    <!-- CRITICAL: PhoneDataListenerService must declare the message paths it handles -->
    <service
        android:name=".PhoneDataListenerService"
        android:enabled="true"
        android:exported="true">
        <intent-filter>
            <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
            <data android:host="*" android:pathPrefix="/heart_rate" android:scheme="wear" />
            <data android:host="*" android:pathPrefix="/sensor_data" android:scheme="wear" />
        </intent-filter>
    </service>

    <!-- Query Samsung Health service -->
    <queries>
        <package android:name="com.samsung.android.service.health.tracking" />
    </queries>
</application>
```

### Phone-side manifest additions

```xml
<!-- Companion app paired with the watch -->
<meta-data
    android:name="com.google.android.wearable.app"
    android:resource="@xml/wear" />

<!-- Same PhoneDataListenerService on the phone side -->
<service
    android:name=".PhoneDataListenerService"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <data android:host="*" android:pathPrefix="/heart_rate" android:scheme="wear" />
        <data android:host="*" android:pathPrefix="/sensor_data" android:scheme="wear" />
    </intent-filter>
</service>
```

---

## 11. Permissions Required

| Permission                              | When requested  | Why                                   |
|-----------------------------------------|-----------------|---------------------------------------|
| `BODY_SENSORS`                          | Runtime (API<35)| Samsung Health HR access              |
| `health.READ_HEART_RATE`                | Runtime (API 35+)| Android 15+ health permission        |
| `ACTIVITY_RECOGNITION`                  | Runtime         | Android SensorManager accelerometer   |
| `WAKE_LOCK`                             | Manifest only   | Keep CPU alive when screen is off     |
| `FOREGROUND_SERVICE`                    | Manifest only   | Background sensor tracking            |
| `FOREGROUND_SERVICE_HEALTH`             | Manifest only   | Health foreground service type        |

### Runtime permission request pattern (Kotlin)

```kotlin
val bodySensorPermission = if (Build.VERSION.SDK_INT >= 35)
    "android.permission.health.READ_HEART_RATE"
else
    Manifest.permission.BODY_SENSORS

ActivityCompat.requestPermissions(
    this,
    arrayOf(bodySensorPermission, Manifest.permission.ACTIVITY_RECOGNITION),
    PERMISSION_REQUEST_CODE
)

// Handle result — returns true only if ALL permissions granted
override fun onRequestPermissionsResult(...) {
    val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
    pendingPermissionResult?.success(allGranted)
}
```

---

## 12. Common Issues and How to Fix Them

### Watch/Sensor Issues

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `HealthTrackingService` crashes when screen turns off | Activity context used instead of applicationContext | Use `applicationContext` in `HealthTrackingManager` constructor |
| `onConnectionFailed` fires immediately | Samsung Health service not installed / watch in low-power mode | Check Samsung Health is installed and watch is awake |
| Capability check fails with exception | Called `trackingCapability` BEFORE `onConnectionSuccess` | Always check capabilities INSIDE `onConnectionSuccess()` callback |
| HR tracker returns all `hrStatus == 0` (invalid) | Watch not worn correctly, or no skin contact | Only pass `HR_STATUS_VALID == 1` readings to the AI |
| Accelerometer not available | Emulator or device without hardware sensor | Catch `AccelerometerUnavailableException`, continue with HR only |
| `SensorInitializationException` on `registerListener` | Race condition or permission denied | Request `ACTIVITY_RECOGNITION` before calling `startTracking()` |

### Watch-to-Phone Transport Issues

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `No connected nodes` logged | Bluetooth not paired, or Pulsify not on phone | Pair via Wear OS / Galaxy Wearable app first |
| Capability discovery finds 0 nodes, falls back | `wear.xml` missing on phone side | Add `wear.xml` with `pulsify_phone_app` capability |
| Message sent but phone never receives it | `PhoneDataListenerService` intent-filter path mismatch | Check `pathPrefix` in phone manifest matches the message path exactly |
| `PhoneDataListenerService` never fires | Service not exported, or missing intent-filter | Set `android:exported="true"` and add the `MESSAGE_RECEIVED` intent-filter |
| Batch discarded because buffer is full | Phone disconnected during active tracking | Log and accept data loss; reconnect automatically when phone is near |

### Flutter/Dart Issues

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `MissingPluginException` on channel call | Plugin not registered in `configureFlutterEngine` | Call `GeneratedPluginRegistrant.registerWith(flutterEngine)` |
| EventChannel stream never emits | `onListen` sets sink, but native side sends before Flutter listens | Native side checks `eventSink != null` before calling `success()` |
| `Bad state: Stream has already been listened to` | EventChannel used as non-broadcast stream by multiple listeners | Use `receiveBroadcastStream()`, store as field, reuse the same stream |
| `type '_Map<Object?, Object?>' is not a subtype of 'Map<String, dynamic>'` | Flutter gets `Map<Object?, Object?>` from native | Wrap with `Map<String, dynamic>.from(event as Map)` |
| TFLite model input shape mismatch | Buffer length != 320, or features != 4 | `ClassifyActivityUseCase` validates both before calling predict |
| Model outputs gibberish at rest | Model trained only for active states | REST gate: if BPM < 85, return 'Calm' and skip model |

### Lifecycle Issues

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Tracking stops when app goes to background | No wake lock | Acquire `PARTIAL_WAKE_LOCK` on `startHeartRate`, release on stop |
| Event sink is null after app resumes | Flutter engine rebuilt, sinks not re-registered | Re-register sinks in `configureFlutterEngine` (called on every engine init) |
| `PhoneDataListenerService.eventSink` is null when data arrives | App not running when watch sends data | Call `launchMainActivity()` as fallback to start the app |
| Multiple connection attempts overlap | No guard against re-connection | Check `isServiceConnected && healthTrackingService != null`, return early |

---

## 13. Lifecycle and Threading Rules

### Threading model

```
Kotlin side:
  - HealthTracker callbacks:  background thread (Binder thread pool)
  - SensorEventListener:      background thread (sensor thread)
  - WearableListenerService:  background thread
  - ALL EventSink calls:      MUST be on main thread
  - Use: mainHandler.post { eventSink?.success(...) }

Flutter/Dart side:
  - EventChannel stream:      main isolate
  - TFLite inference:         runs synchronously on main isolate
    (for heavy models, move to a compute isolate)
```

### Activity lifecycle

```
onCreate   -> initializeWakeLock(), initializeHealthTracking()
onResume   -> if (isTrackingActive) acquireWakeLock()
onPause    -> tracking continues, wake lock keeps CPU alive
onDestroy  -> releaseWakeLock(), disconnect(), null out all sinks
```

### EventSink lifecycle

```
onListen(sink)  -> store sink reference (heartRateEventSink = events)
onCancel()      -> null out reference (heartRateEventSink = null)

// Always null-check before calling:
mainHandler.post { heartRateEventSink?.success(data) }
```

---

## 14. Checklist: Adapting This Pattern to Another Project

Use this checklist when building a new Flutter + Kotlin native bridge with live sensor data.

### Android setup

- [ ] Samsung Health SDK AAR placed in `android/app/libs/`
- [ ] `build.gradle` references the AAR: `implementation fileTree(dir: 'libs', include: ['*.aar'])`
- [ ] `build.gradle` includes Wearable Data Layer: `implementation 'com.google.android.gms:play-services-wearable:18.x.x'`
- [ ] `kotlinx-serialization` plugin added for JSON encoding on the watch side
- [ ] `application` class extends or registers sensors properly (see `PulsifyApp.kt`)

### AndroidManifest.xml

- [ ] `BODY_SENSORS` and `health.READ_HEART_RATE` permissions declared
- [ ] `ACTIVITY_RECOGNITION` declared
- [ ] `WAKE_LOCK` declared
- [ ] `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_HEALTH` declared
- [ ] `PhoneDataListenerService` declared with `exported=true` and `MESSAGE_RECEIVED` intent-filter
- [ ] Correct `pathPrefix` values in the intent-filter match your message paths exactly
- [ ] `<queries>` block includes Samsung Health package name
- [ ] `wear.xml` capability file created and referenced via meta-data (phone side)

### Kotlin native bridge

- [ ] `HealthTrackingManager` uses `applicationContext` (not activity context)
- [ ] Capability check happens inside `onConnectionSuccess()` callback, not before
- [ ] All `EventSink.success()` calls wrapped in `mainHandler.post { }`
- [ ] `PhoneDataListenerService` has static `eventSink` set from `MainActivity.configureFlutterEngine`
- [ ] All channel names are exact strings that match Dart side
- [ ] Sensor listener unregistered in `stopTracking()` to prevent battery drain
- [ ] Wake lock acquired on start, released on stop and `onDestroy`
- [ ] JSON serialization uses `@Serializable` + `kotlinx.serialization.json.Json.encodeToString()`

### Flutter / Dart side

- [ ] All `EventChannel.receiveBroadcastStream()` results stored as fields (not re-created each time)
- [ ] `Map<String, dynamic>.from(event as Map)` used when deserializing EventChannel data
- [ ] `MethodChannel` calls have timeouts (`Future.timeout(Duration(seconds: 10))`)
- [ ] Retryable operations use exponential backoff
- [ ] `PlatformException` caught and mapped to typed domain errors
- [ ] Model loaded once at startup (`await classifier.loadModel()`) before any classification
- [ ] Input buffer validated: exactly 320 samples, each with 4 features
- [ ] REST gate applied before TFLite inference (BPM threshold check)
- [ ] Sliding window buffer implemented to accumulate 32-sample batches into 320-sample windows
- [ ] `dispose()` called on `WatchBridgeService` when no longer needed

### TFLite model

- [ ] Model file placed in `assets/model/` and declared in `pubspec.yaml` under `flutter.assets`
- [ ] Input shape verified against model: `[1, 320, 4]`
- [ ] Output shape verified against model: `[1, 3]`
- [ ] `tflite_flutter` package added to `pubspec.yaml`
- [ ] Model shapes validated at load time (throw if mismatch)
- [ ] Inference runs on the right thread (move to compute isolate for heavy models)

### Testing

- [ ] Test mode data endpoint (`getTestModeData`) can be called from Flutter to inspect raw sensor values
- [ ] `HeartBpmAdapter.setManualBpm()` used for unit testing the classifier without real hardware
- [ ] `ActivityClassifierViewModel` can be tested by injecting a mock `ClassifyActivityUseCase`
- [ ] `WatchBridgeService` can be mocked at the `MethodChannel` level using `TestDefaultBinaryMessengerBinding`

---

*Generated from Pulsify source — last updated March 2026*
