# Smartwatch Module Extraction Guide

How to lift the Samsung Health Sensor (Galaxy Watch) integration out of Pulsify and drop it into a new Flutter + Kotlin project.

---

## Architecture Overview

The watch integration spans three layers:

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter (Dart) — UI + Business Logic                       │
│  WatchBridgeService  ←→  MethodChannel / EventChannel       │
└──────────────────────────┬──────────────────────────────────┘
                           │ Platform Channel
                           │  "com.pulsify.watch/data"
                           │  "com.pulsify.watch/heartrate" (EventChannel)
                           │  "com.pulsify.watch/sync"
                           │  "com.pulsify.watch/transmission" (EventChannel)
┌──────────────────────────▼──────────────────────────────────┐
│  Kotlin Native (Android) — Samsung Health SDK + Sensors     │
│  MainActivity → HealthTrackingManager → WatchSensorService  │
│  WatchToPhoneSyncManager ← PhoneDataListenerService         │
└─────────────────────────────────────────────────────────────┘
```

Data flows:
- **Watch → Phone**: `WatchSensorService` batches accelerometer + HR, sends via `Wearable.getMessageClient` on path `/sensor_data`
- **Watch screen**: `WatchBridgeService` calls Kotlin native directly via MethodChannel
- **Phone receives watch data**: `PhoneDataListenerService` (WearableListenerService) forwards to Flutter via a static `EventChannel.EventSink`

---

## Files to Extract

### Dart / Flutter layer

| File (relative to `lib/`) | Purpose |
|---|---|
| `services/watch_bridge.dart` | Core service — MethodChannel + EventChannel wrapper |
| `services/watch_to_phone_sync.dart` | Helper to push data from watch → phone |
| `services/heart_rate_service.dart` | High-level HR service used by UI |
| `services/heart_rate_data_manager.dart` | Data buffering / persistence |
| `models/heart_rate_data.dart` | `HeartRateData` DTO |
| `models/sensor_batch.dart` | `SensorBatch` — 32-sample accelerometer + HR packet |
| `models/tracked_data.dart` | `TrackedData` — HR, IBI, HRV, SpO2 |
| `models/sensor_error.dart` | `SensorError` exception |
| `models/sensor_error_code.dart` | `SensorErrorCode` enum |
| `models/sensor_status.dart` | `SensorStatus` enum |
| `models/connection_state.dart` | `ConnectionState` enum |
| `models/permission_status.dart` | `PermissionStatus` enum |
| `screens/wear/heart_rate_watch_screen.dart` | Watch-side heart rate screen |
| `screens/wear/wear_heart_rate_screen.dart` | Alternate wear HR screen |
| `screens/wear/sensor_permission_rationale_screen.dart` | Permission rationale screen |
| `screens/heart_rate_monitor_screen.dart` | Phone-side monitor UI |
| `screens/phone/phone_heart_rate_screen.dart` | Phone receiving-side screen |
| `screens/sensor_permission_screen.dart` | Permission request screen |

### Kotlin / Android layer

| File (relative to `android/app/src/main/kotlin/com/example/Pulsify/`) | Purpose |
|---|---|
| `MainActivity.kt` | Registers all MethodChannels and EventChannels |
| `HealthTrackingManager.kt` | Samsung Health SDK lifecycle + heart rate tracker |
| `WatchSensorService.kt` | Accelerometer collection → batch transmission via Wearable API |
| `WatchToPhoneSyncManager.kt` | Sends heart rate batches to phone |
| `PhoneDataListenerService.kt` | WearableListenerService — receives data on the **phone** side |
| `TrackedData.kt` | Kotlin data model mirroring Dart's `TrackedData` |

### Android manifests / build files

From `android/app/src/main/AndroidManifest.xml`:
- `BODY_SENSORS` permission
- `health.READ_HEART_RATE` permission (Android 15+)
- `WAKE_LOCK` permission
- `PhoneDataListenerService` registration with `BIND_LISTENER` intent filter

From `android/app/build.gradle.kts`:
- Samsung Health Sensor SDK AAR dependency
- Wearable dependency (`com.google.android.gms:play-services-wearable`)
- `kotlinx.serialization` plugin

---

## Step-by-Step: Setting Up the New Project

### 1. Create the Flutter project

```bash
flutter create --org com.yourcompany --platforms android watch_health_module
cd watch_health_module
```

### 2. Add Dart dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  permission_handler: ^11.3.0
  logger: ^2.0.2
  provider: ^6.1.0          # or riverpod if you prefer

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 3. Copy Dart files

Copy the files listed in the table above into the equivalent paths under `lib/`.

Rename the package import prefix from `Pulsify` to your new package name:

```bash
# PowerShell one-liner (run from project root)
Get-ChildItem -Recurse -Filter *.dart lib/ |
  ForEach-Object { (Get-Content $_.FullName) -replace "package:pulsify/", "package:watch_health_module/" |
  Set-Content $_.FullName }
```

### 4. Add Samsung Health Sensor SDK AAR

1. Download the Samsung Health Sensor SDK from [Samsung Developers](https://developer.samsung.com/health/galaxy-watch/overview.html).
2. Place the AAR in `android/app/libs/`:

```
android/
  app/
    libs/
      samsung-health-sensor-api-1.x.x.aar
```

3. In `android/app/build.gradle.kts`, add:

```kotlin
dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar", "*.jar"))))
    implementation("com.google.android.gms:play-services-wearable:18.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
}
```

4. Apply the serialization plugin in `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"
    id("dev.flutter.flutter-gradle-plugin")
}
```

In the root `android/build.gradle.kts` (or `settings.gradle.kts`):

```kotlin
plugins {
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0" apply false
}
```

### 5. Copy Kotlin files

Copy the Kotlin files listed above into:

```
android/app/src/main/kotlin/com/yourcompany/watch_health_module/
```

Update the package declaration at the top of each file:

```kotlin
// Before
package com.example.pulsify

// After
package com.yourcompany.watch_health_module
```

### 6. Update channel names (optional but recommended)

The channel identifiers are currently `com.pulsify.watch/*`. Update them consistently in **both** Dart and Kotlin:

**Dart** (`lib/services/watch_bridge.dart`):
```dart
static const MethodChannel _methodChannel =
    MethodChannel('com.yourcompany.watchhealth/data');
static const MethodChannel _syncChannel =
    MethodChannel('com.yourcompany.watchhealth/sync');
static const EventChannel _heartRateEventChannel =
    EventChannel('com.yourcompany.watchhealth/heartrate');
```

**Kotlin** (`MainActivity.kt`):
```kotlin
private val CHANNEL = "com.yourcompany.watchhealth/data"
private val EVENT_CHANNEL = "com.yourcompany.watchhealth/heartrate"
private val TRANSMISSION_EVENT_CHANNEL = "com.yourcompany.watchhealth/transmission"
```

### 7. Update `AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Sensor permissions -->
    <uses-permission android:name="android.permission.BODY_SENSORS" />
    <uses-permission android:name="android.permission.health.READ_HEART_RATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- Required for Samsung Health Sensor SDK -->
    <queries>
        <package android:name="com.samsung.android.wear.shealth" />
    </queries>

    <application ...>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            ... >
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Phone-side listener: receives data from the Galaxy Watch -->
        <service
            android:name=".PhoneDataListenerService"
            android:exported="true">
            <intent-filter>
                <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
                <data
                    android:host="*"
                    android:pathPrefix="/"
                    android:scheme="wear" />
            </intent-filter>
        </service>

    </application>
</manifest>
```

---

## Flutter ↔ Kotlin Bridge Reference

### Method Channel: `com.pulsify.watch/data`

| Method (Dart calls) | Kotlin handler | Returns |
|---|---|---|
| `requestPermission` | Requests `BODY_SENSORS` / `health.READ_HEART_RATE` | `bool` |
| `checkPermission` | Queries current permission status | `String` (`"granted"` / `"denied"` / `"notDetermined"`) |
| `connectWatch` | Calls `HealthTrackingManager.connect()` | `bool` |
| `disconnectWatch` | Calls `HealthTrackingManager.disconnect()` | `void` |
| `startTracking` | Calls `HealthTrackingManager.startTracking()` | `bool` |
| `stopTracking` | Calls `HealthTrackingManager.stopTracking()` | `void` |
| `getLastHeartRate` | Returns `lastHeartRateData` map | `Map<String, Any?>?` |
| `isConnected` | Checks `HealthTrackingManager.isConnected()` | `bool` |
| `isTracking` | Returns `isTrackingActive` flag | `bool` |

### Event Channel: `com.pulsify.watch/heartrate`

Emits a `Map<String, dynamic>` for every heart rate reading:
```dart
{
  "bpm": 72,
  "ibiValues": [834, 812, 845],
  "timestamp": 1709812345678,   // epoch ms
  "status": "active"
}
```

Consume in Dart:
```dart
_heartRateEventChannel
    .receiveBroadcastStream()
    .listen((event) {
      final data = HeartRateData.fromJson(Map<String, dynamic>.from(event));
      // use data
    });
```

### Event Channel: `com.pulsify.watch/transmission`

Fires whenever Samsung Health batches a sensor flush:
```dart
{ "timestamp": 1709812345678 }
```

### Method Channel: `com.pulsify.watch/sync`

| Method | Returns | Notes |
|---|---|---|
| `sendHeartRateToPhone` | `bool` | Sends a single JSON-encoded `HeartRateData` |
| `sendBatchToPhone` | `bool` | Sends a JSON array of `HeartRateData` objects |
| `checkPhoneConnection` | `bool` | Uses `Wearable.getNodeClient` |
| `getConnectedNodesCount` | `int` | Number of paired phones reachable |

---

## Key Kotlin Classes

### `HealthTrackingManager`

```kotlin
HealthTrackingManager(
    context = applicationContext,
    onHeartRateData = { data: HeartRateData -> /* push to EventSink */ },
    onError        = { code, message -> /* push error to EventSink */ },
    onTransmission = { /* notify Flutter of batch flush */ }
)
```

- Calls `HealthTrackingService(connectionListener, context).connectService()`
- Uses `HealthTrackerType.HEART_RATE_CONTINUOUS`
- Reads `ValueKey` fields for BPM, IBI, SpO2 from each `DataPoint`
- Contains retry/reconnect logic if `onConnectionFailed` fires

### `WatchSensorService`

- Registers `SensorManager.TYPE_ACCELEROMETER` at `SENSOR_DELAY_GAME` (~50 Hz)
- Buffers 32 samples then calls `sendBatchToPhone()` at most once per second
- Serialises a `SensorBatch` JSON:

```json
{
  "type": "sensor_batch",
  "timestamp": 1709812345678,
  "bpm": 72,
  "sampleRate": 32,
  "count": 32,
  "accelerometer": [[0.12, -0.45, 9.81], ...]
}
```

- Sends via `Wearable.getMessageClient(context).sendMessage(nodeId, "/sensor_data", bytes)`

### `PhoneDataListenerService`

Extends `WearableListenerService`. Handles paths:
- `/heart_rate` → parses single `HeartRateData`, forwards to `eventSink`
- `/heart_rate_batch` → parses JSON array, forwards each reading
- `/sensor_data` → parses `SensorBatch`, forwards to `sensorBatchEventSink`

Register the static sinks from `MainActivity` after the Flutter engine is ready.

---

## Data Models (Dart ↔ Kotlin parity)

### `HeartRateData` (Dart) / `HeartRateData` (Kotlin)

| Field | Type | Notes |
|---|---|---|
| `bpm` | `int?` | Null during measurement warmup |
| `timestamp` | `DateTime` / `Long` | Epoch ms |
| `status` | `SensorStatus` | `active`, `measuring`, `lowAccuracy`, `unreliable`, `deviceNotWorn` |
| `ibiValues` | `List<int>` | Inter-beat intervals in ms |

### `TrackedData`

| Field | Type |
|---|---|
| `hr` | `int` |
| `ibiValues` | `List<int>` |
| `hrv` | `double` (RMSSD in ms) |
| `spo2` | `int` (%) |
| `timestamp` | `DateTime` |
| `status` | `SensorStatus` |

HRV is computed client-side via RMSSD:
```dart
static double calculateHRV(List<int> ibiList) {
  // √( mean( (IBI[i+1] - IBI[i])² ) )
}
```

### `SensorBatch`

Holds 32 × 4-feature vectors `[accX, accY, accZ, bpm]` ready for an activity-classification ML model.

---

## Wake Lock

The watch app acquires a partial wake lock (`PARTIAL_WAKE_LOCK`) when tracking starts so heart-rate collection continues with the screen off:

```kotlin
// Acquire (in MainActivity when startTracking succeeds)
wakeLock?.acquire(10 * 60 * 1000L)  // max 10 min, renew as needed

// Release
wakeLock?.release()
```

Ensure `android.permission.WAKE_LOCK` is in the manifest.

---

## Permissions Handling

### Android 15+ (API 35)

Samsung Health Sensor SDK requires `android.permission.health.READ_HEART_RATE` (a `HEALTH` permission group). Request it at runtime via the native method channel — `permission_handler` does **not** cover this permission family.

```kotlin
// MainActivity.kt
private fun requestHealthPermission(result: MethodChannel.Result) {
    if (Build.VERSION.SDK_INT >= 35) {
        ActivityCompat.requestPermissions(
            this,
            arrayOf("android.permission.health.READ_HEART_RATE"),
            PERMISSION_REQUEST_CODE
        )
        pendingPermissionResult = result
    } else {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.BODY_SENSORS),
            PERMISSION_REQUEST_CODE
        )
        pendingPermissionResult = result
    }
}
```

Override `onRequestPermissionsResult` and call `pendingPermissionResult?.success(granted)`.

### Dart side

```dart
// In WatchBridgeService
final granted = await _methodChannel.invokeMethod<bool>('requestPermission');
```

---

## Minimal `MainActivity.kt` Skeleton for New Project

```kotlin
package com.yourcompany.watch_health_module

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL        = "com.yourcompany.watchhealth/data"
    private val EVENT_CHANNEL  = "com.yourcompany.watchhealth/heartrate"
    private val TRANS_CHANNEL  = "com.yourcompany.watchhealth/transmission"
    private val SYNC_CHANNEL   = "com.yourcompany.watchhealth/sync"

    private var heartRateEventSink: EventChannel.EventSink? = null
    private var transmissionEventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private lateinit var healthManager: HealthTrackingManager
    private lateinit var syncManager: WatchToPhoneSyncManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        healthManager = HealthTrackingManager(
            context        = applicationContext,
            onHeartRateData = { data ->
                mainHandler.post { heartRateEventSink?.success(data.toMap()) }
            },
            onError        = { code, msg ->
                mainHandler.post { heartRateEventSink?.error(code, msg, null) }
            },
            onTransmission = {
                mainHandler.post {
                    transmissionEventSink?.success(
                        mapOf("timestamp" to System.currentTimeMillis())
                    )
                }
            }
        )
        syncManager = WatchToPhoneSyncManager(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Data / command channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission"  -> requestHealthPermission(result)
                    "checkPermission"    -> checkHealthPermission(result)
                    "connectWatch"       -> healthManager.connect { ok, err ->
                        mainHandler.post { if (ok) result.success(true) else result.success(false) }
                    }
                    "disconnectWatch"    -> { healthManager.disconnect(); result.success(null) }
                    "startTracking"      -> result.success(healthManager.startTracking())
                    "stopTracking"       -> { healthManager.stopTracking(); result.success(null) }
                    "isConnected"        -> result.success(healthManager.isConnected())
                    else                 -> result.notImplemented()
                }
            }

        // Heart-rate event stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    heartRateEventSink = sink
                }
                override fun onCancel(args: Any?) {
                    heartRateEventSink = null
                }
            })

        // Transmission event stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TRANS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    transmissionEventSink = sink
                }
                override fun onCancel(args: Any?) {
                    transmissionEventSink = null
                }
            })

        // Sync channel (watch → phone messaging)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYNC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPhoneConnection"    -> syncManager.checkConnection(result)
                    "getConnectedNodesCount"  -> syncManager.getNodeCount(result)
                    else                      -> result.notImplemented()
                }
            }
    }
}
```

---

## Checklist

- [ ] Samsung Health Sensor SDK AAR added to `android/app/libs/`
- [ ] `play-services-wearable` dependency in `build.gradle.kts`
- [ ] `kotlinx.serialization` plugin applied
- [ ] `BODY_SENSORS` (+ `health.READ_HEART_RATE` for API 35+) in `AndroidManifest.xml`
- [ ] `WAKE_LOCK` permission in `AndroidManifest.xml`
- [ ] `PhoneDataListenerService` registered in `AndroidManifest.xml` with wear intent filter
- [ ] All Dart package imports updated from `package:pulsify/` → your package
- [ ] Channel name strings updated consistently in Dart + Kotlin
- [ ] `WatchBridgeService` injected / provided during app startup (before any UI calls it)
- [ ] Runtime permission request wired up before calling `connectWatch`
- [ ] `PhoneDataListenerService.eventSink` assigned after Flutter engine is ready
