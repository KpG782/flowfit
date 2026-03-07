# Pulsify — Android & Smartwatch Integration: Full Technical Reference

> Generated March 7, 2026. Intended for sharing with a second AI for context, code review, or continued development.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Android Build Configuration](#2-android-build-configuration)
3. [AndroidManifest](#3-androidmanifest)
4. [Kotlin Native Layer](#4-kotlin-native-layer)
   - [PulsifyApp.kt](#41-PulsifyAppkt)
   - [MainActivity.kt](#42-mainactivitykt)
   - [HealthTrackingManager.kt](#43-healthtrackingmanagerkt)
   - [WatchSensorService.kt](#44-watchsensorservicekt)
   - [WatchToPhoneSyncManager.kt](#45-watchtophonesyncmanagerkt)
   - [PhoneDataListenerService.kt](#46-phonedatalistenerservicekt)
   - [TrackedData.kt](#47-trackeddatakt)
5. [Flutter / Dart Layer](#5-flutter--dart-layer)
   - [pubspec.yaml — Key Dependencies](#51-pubspecyaml--key-dependencies)
   - [main_wear.dart — Wear OS Entry Point](#52-main_weardart--wear-os-entry-point)
   - [WatchBridgeService](#53-watchbridgeservice)
   - [WatchToPhoneSync](#54-watchtophonesync)
   - [PhoneDataListener](#55-phonedatalistener)
   - [HeartRateService](#56-heartrateservice)
   - [HeartRateDataManager](#57-heartratadatamanager)
6. [Data Models](#6-data-models)
7. [AI / Activity Classifier Pipeline](#7-ai--activity-classifier-pipeline)
8. [Platform Channel Registry](#8-platform-channel-registry)
9. [Samsung Health SDK Details](#9-samsung-health-sdk-details)
10. [Critical Design Notes](#10-critical-design-notes)
11. [Possible Issues & Bugs](#11-possible-issues--bugs)

---

## 1. Architecture Overview

Pulsify uses a **dual-role Android architecture** — a single repository is intended to produce both a **Galaxy Watch (Wear OS) app** and a **phone companion app**. The same package name (`com.example.pulsify`) is used on both sides, which is required for the Wearable Data Layer API to route messages between them.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GALAXY WATCH (Wear OS)                       │
│                                                                     │
│  Samsung Health Sensor API (AAR)                                    │
│       └─► HealthTrackingManager                                     │
│               ├─► Heart Rate (continuous, with IBI)                 │
│               └─► WatchSensorService (accelerometer @ ~32 Hz)       │
│                       └─► sendBatchToPhone() via MessageClient       │
│                                                                     │
│  WatchBridgeService (Dart ↔ Native via MethodChannel/EventChannel)  │
│  TFLiteActivityClassifier (optional on-watch AI inference)          │
└───────────────────────┬─────────────────────────────────────────────┘
                        │ Wearable Data Layer API (Google Play Services)
                        │  /heart_rate   — HeartRateData JSON
                        │  /heart_rate_batch — TrackedData[] JSON
                        │  /sensor_data  — SensorBatch JSON (accel+bpm)
                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          PHONE (Android)                            │
│                                                                     │
│  PhoneDataListenerService (WearableListenerService)                 │
│       ├─► eventSink (com.pulsify.phone/heartrate EventChannel)      │
│       └─► sensorBatchEventSink (com.pulsify.phone/sensor_data)      │
│                                                                     │
│  Flutter Phone App                                                  │
│       ├─► PhoneDataListener (Dart) — heartRateStream, sensorBatch  │
│       ├─► HeartRateService — zones, history                         │
│       ├─► HeartRateDataManager — SQLite buffer, RMSSD/HRV           │
│       └─► TFLiteActivityClassifier — 320-sample window → 3 classes  │
└─────────────────────────────────────────────────────────────────────┘
```

**Data flow summary:**
1. Samsung Health SDK delivers HR + IBI on the **watch** side.
2. Accelerometer is captured at ~32 Hz and batched into 32-sample packets.
3. Every ~1 second a `SensorBatch` (32× `[accX, accY, accZ]` + BPM) is sent to the phone over the **Wearable Data Layer** at path `/sensor_data`.
4. Phone's `PhoneDataListenerService` (a `WearableListenerService`) receives it and fires an `EventChannel` event into Dart.
5. The Dart `tracker_page.dart` feeds these into a **320-sample sliding window** and runs **TFLite inference** → `[Stress%, Cardio%, Strength%]`.

---

## 2. Android Build Configuration

### `android/settings.gradle.kts`
```kotlin
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
            ?: error("flutter.sdk not set in local.properties")
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application")           version "8.9.1"  apply false
    id("org.jetbrains.kotlin.android")       version "2.1.0"  apply false
}

include(":app")
```

### `android/build.gradle.kts`
- Sets JVM toolchain to Java 17 across all subprojects.
- Redirects build outputs to `../../build` (Flutter convention).

### `android/gradle.properties`
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m
android.useAndroidX=true
android.enableJetifier=true
kotlin.jvm.target.validation.mode=warning
```

### `android/app/build.gradle.kts`
```kotlin
android {
    namespace  = "com.example.pulsify"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility         = JavaVersion.VERSION_17
        targetCompatibility         = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "17" }

    defaultConfig {
        applicationId = "com.example.pulsify"
        minSdk        = 30   // ← Required for Wear OS 3 + Samsung Health Sensor API
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }
}

dependencies {
    // Samsung Health Sensor API — local AAR (NOT on Maven)
    implementation(files("libs/samsung-health-sensor-api-1.4.1.aar"))

    // AndroidX Health Services
    implementation("androidx.health:health-services-client:1.0.0-beta03")

    // Wear OS
    implementation("androidx.wear:wear:1.3.0")
    implementation("com.google.android.support:wearable:2.9.0")
    implementation("com.google.android.wearable:wearable:2.9.0")

    // Wearable Data Layer (watch ↔ phone messaging)
    implementation("com.google.android.gms:play-services-wearable:18.1.0")

    // Kotlin
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## 3. AndroidManifest

### Permissions
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.BODY_SENSORS" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />  <!-- Android 15+ -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### Hardware Feature Declaration
```xml
<uses-feature android:name="android.hardware.type.watch" />
```
> ⚠️ This marks the APK as a **watch app** in the Play Store. It will NOT be installable on phones unless this line is removed or marked `required="false"`.

### Application-level Metadata
```xml
<!-- Standalone Wear OS app (no phone companion required to launch) -->
<meta-data android:name="com.google.android.wearable.standalone" android:value="true" />

<!-- Disable Impeller rendering engine (fixes gralloc4 format errors on some watches) -->
<meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="false" />
```

### Services
```xml
<!-- Foreground sensor tracker (runs on watch) -->
<service android:name=".SensorTrackingService"
         android:foregroundServiceType="health" />

<!-- Receives Data Layer messages from watch ON THE PHONE -->
<service android:name=".PhoneDataListenerService" android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <data android:host="*" android:pathPrefix="/heart_rate"  android:scheme="wear" />
        <data android:host="*" android:pathPrefix="/sensor_data" android:scheme="wear" />
        <!-- NOTE: /heart_rate_batch path is NOT registered here -->
    </intent-filter>
</service>
```

### Package Queries (Samsung Health)
```xml
<queries>
    <package android:name="com.samsung.android.service.health.tracking" />
</queries>
```

---

## 4. Kotlin Native Layer

### 4.1 PulsifyApp.kt
```kotlin
class PulsifyApp : Application() {
    companion object {
        lateinit var instance: PulsifyApp private set
    }
    override fun onCreate() {
        super.onCreate()
        instance = this
    }
}
```
Simple `Application` subclass registered in the manifest (`android:name=".PulsifyApp"`). Provides a static singleton for `applicationContext` access.

---

### 4.2 MainActivity.kt

Extends `FlutterActivity`. Registers **all platform channels** in `configureFlutterEngine()`.

#### Channel registrations

| Channel | Type | Purpose |
|---|---|---|
| `com.pulsify.watch/data` | MethodChannel | Samsung Health SDK control (connect, startHR, etc.) |
| `com.pulsify.watch/sync` | MethodChannel | Send HR/batch from watch to phone |
| `com.pulsify.watch/heartrate` | EventChannel | Real-time HR stream from Samsung Health SDK |
| `com.pulsify.watch/transmission` | EventChannel | Fires each time a sensor batch is transmitted |
| `com.pulsify.phone/data` | MethodChannel | Phone-side listener control |
| `com.pulsify.phone/heartrate` | EventChannel | HR received on phone from watch |
| `com.pulsify.phone/sensor_data` | EventChannel | Accel+HR batch received on phone from watch |
| `com.pulsify.geofence/native` | MethodChannel | Register/unregister geofences |
| `com.pulsify.geofence/events` | EventChannel | Geofence enter/exit callbacks |

#### Key fields
```kotlin
private var healthTrackingManager: HealthTrackingManager? = null
private var watchToPhoneSyncManager: WatchToPhoneSyncManager? = null
private var heartRateEventSink: EventChannel.EventSink? = null
private var transmissionEventSink: EventChannel.EventSink? = null
private val mainHandler = Handler(Looper.getMainLooper())
private val scope = CoroutineScope(Dispatchers.Main)
private var wakeLock: PowerManager.WakeLock? = null
```

#### Initialization flow
```
onCreate()
  ├─ window.addFlags(FLAG_KEEP_SCREEN_ON)
  ├─ initializeWakeLock()      → acquires PARTIAL_WAKE_LOCK "Pulsify::HeartRateTracking"
  └─ initializeHealthTracking()
        ├─ HealthTrackingManager(applicationContext, onHeartRateData, onError, onTransmission)
        └─ WatchToPhoneSyncManager(applicationContext)

configureFlutterEngine()
  └─ Registers all channels listed above
     PhoneDataListenerService.eventSink ← wired here from static companion field
```

---

### 4.3 HealthTrackingManager.kt

Wraps the **Samsung Health Sensor API**. All callbacks are fired asynchronously by the Samsung SDK.

```kotlin
class HealthTrackingManager(
    private val context: Context,                       // MUST be applicationContext
    private val onHeartRateData: (HeartRateData) -> Unit,
    private val onError: (String, String?) -> Unit,
    private val onTransmission: (() -> Unit)? = null
)
```

#### Connection lifecycle
```
connect(callback)
  → HealthTrackingService(connectionListener, context.applicationContext)
  → connectService()

connectionListener.onConnectionSuccess()
  → hasHeartRateCapability()    ← MUST be called here, not before
  → callback(true/false, errorMsg?)

connectionListener.onConnectionEnded() / onConnectionFailed()
  → healthTrackingService = null
  → callback(false, reason)
```

#### Tracking
```
startTracking()
  → healthTrackingService.getHealthTracker(HEART_RATE_CONTINUOUS)
  → heartRateTracker.setEventListener(trackerEventListener)
  → sensorService.startTracking()   ← starts accelerometer

trackerEventListener.onDataReceived(dataPoints)
  → processDataPoint(dataPoint)
        → extracts: HEART_RATE (Int), HEART_RATE_STATUS (Int), IBI_LIST (IntArray), IBI_STATUS_LIST (IntArray)
        → isHRValid(status) = (status == 1)
        → valid IBI = ibiValues where ibiStatuses[i] == 0 && ibiValues[i] != 0
        → appends to validHrData (capped at 40 entries)
        → sensorService.currentHeartRate = hrValue
        → calls onHeartRateData(HeartRateData(...))
```

#### In-memory HR buffer
```kotlin
private val validHrData = ArrayList<TrackedData>()  // max 40 entries
fun getValidHrData(): ArrayList<TrackedData>        // thread-safe copy
fun clearValidHrData()                               // thread-safe clear
```

---

### 4.4 WatchSensorService.kt

Captures accelerometer data on the watch and transmits `SensorBatch` packets to the phone via `Wearable.MessageClient`.

```kotlin
companion object {
    const val BUFFER_SIZE = 32                     // samples per batch
    const val MIN_TRANSMISSION_INTERVAL_MS = 1000L // max 1 batch/second
    const val SENSOR_DATA_PATH = "/sensor_data"
    const val SAMPLE_RATE_HZ = 32
}
```

#### Sensor registration
```kotlin
sensorManager.registerListener(
    accelListener,
    accelerometer,
    SensorManager.SENSOR_DELAY_GAME   // ≈ 50 Hz — NOT exactly 32 Hz
)
```

#### Batch transmission logic
```
onSensorChanged(event)
  → add SensorReading to accelBuffer if size < 32
  → if size >= 32 AND time since last send >= 1000ms:
        sendBatchToPhone()
          → Wearable.getNodeClient(context).connectedNodes
            → for first connected node:
                  sendMessage(node.id, "/sensor_data", json.toByteArray())
          → accelBuffer.clear()
          → onTransmissionCallback?.invoke()
```

#### JSON payload (SensorBatch)
```json
{
  "type": "sensor_batch",
  "timestamp": 1741300000000,
  "bpm": 82,
  "sampleRate": 32,
  "count": 32,
  "accelerometer": [
    [0.12, -0.45, 9.81],
    ...32 entries...
  ]
}
```

---

### 4.5 WatchToPhoneSyncManager.kt

Separate sync manager for sending heart rate snapshots and batch data to the phone on demand (as opposed to the continuous push in `WatchSensorService`).

```kotlin
companion object {
    const val MESSAGE_PATH    = "/heart_rate"
    const val BATCH_PATH      = "/heart_rate_batch"
    const val CAPABILITY_NAME = "pulsify_phone_app"
}
```

#### Node discovery strategy (two-step)
```
getConnectedNodes()
  1. CapabilityClient.getCapability("pulsify_phone_app", FILTER_REACHABLE)
     → returns nodes that advertise the "pulsify_phone_app" capability
     → this requires a wear.xml file on the PHONE side (see Issues §11)
  2. Fallback: NodeClient.connectedNodes (all reachable nodes)
```

---

### 4.6 PhoneDataListenerService.kt

A `WearableListenerService` — Android OS starts it automatically when a Data Layer message arrives for the matching path. Runs on the **phone**.

```kotlin
companion object {
    // Static sinks — set by MainActivity.configureFlutterEngine()
    var eventSink: EventChannel.EventSink? = null            // /heart_rate
    var sensorBatchEventSink: EventChannel.EventSink? = null // /sensor_data
}
```

#### Message routing
```
onMessageReceived(messageEvent)
  "/heart_rate"      → handleHeartRateData()   → mainHandler.post { eventSink?.success(map) }
  "/heart_rate_batch" → handleBatchData()       → mainHandler.post { eventSink?.success(map) }
  "/sensor_data"     → handleSensorBatchData() → mainHandler.post { sensorBatchEventSink?.success(map) }
```

If `eventSink == null` when a `/heart_rate` message arrives, it calls `launchMainActivity(data)` to wake the phone app.

---

### 4.7 TrackedData.kt
```kotlin
@Serializable
data class TrackedData(
    var hr: Int = 0,
    var ibi: ArrayList<Int> = ArrayList()
)
```
Minimal Kotlin-side model used for the in-memory HR buffer in `HealthTrackingManager`.

---

## 5. Flutter / Dart Layer

### 5.1 pubspec.yaml — Key Dependencies

```yaml
# Wear OS
wear_plus: ^1.2.0
wear: ^1.1.0
wearable_rotary: ^2.0.3

# Sensors
sensors_plus: ^4.0.2       # Phone accelerometer
heart_bpm: ^2.0.0+0        # Camera-based HR (phone fallback)

# AI
tflite_flutter: ^0.12.1

# Utilities
permission_handler: ^11.0.0
wakelock_plus: ^1.1.0
```

---

### 5.2 main_wear.dart — Wear OS Entry Point

Separate `main()` for the Wear OS build target. Uses `wear_plus` widgets.

```dart
void main() => runApp(const WearApp());

class WearApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            final isAmbient = mode == WearMode.ambient;
            return MaterialApp(
              theme: ThemeData(
                colorScheme: isAmbient
                    ? const ColorScheme.dark(primary: Colors.white24)
                    : const ColorScheme.dark(primary: Color(0xFF00B5FF)),
                scaffoldBackgroundColor: Colors.black,
              ),
              home: WearDashboard(shape: shape, mode: mode),
            );
          },
        );
      },
    );
  }
}
```

---

### 5.3 WatchBridgeService

`lib/services/watch_bridge.dart` — Dart facade over the `com.pulsify.watch/data` and `com.pulsify.watch/heartrate` channels. Used when the Samsung Health SDK is accessed **directly** (i.e., running on the watch itself).

```dart
static const MethodChannel _methodChannel = MethodChannel('com.pulsify.watch/data');
static const EventChannel  _heartRateEventChannel = EventChannel('com.pulsify.watch/heartrate');
static const int _maxRetries = 3;
static const Duration _initialRetryDelay = Duration(milliseconds: 500);
static const Duration _operationTimeout  = Duration(seconds: 10);
```

#### Key methods
| Method | Channel call | Notes |
|---|---|---|
| `requestPermission()` | `requestPermission` | Triggers Android runtime permission dialog |
| `checkPermission()` | `checkPermission` | Returns `'granted'`, `'denied'`, or `'notDetermined'` |
| `connectToWatch()` | `connectWatch` | Has exponential-backoff retry (×3) |
| `disconnectFromWatch()` | `disconnectWatch` | — |
| `isWatchConnected()` | `isWatchConnected` | — |
| `startHeartRateTracking()` | `startHeartRate` | — |
| `stopHeartRateTracking()` | `stopHeartRate` | — |
| `getCurrentHeartRate()` | `getCurrentHeartRate` | Returns `HeartRateData?` |

#### Heart rate stream
```dart
Stream<HeartRateData> get heartRateStream {
    _heartRateStream ??= _heartRateEventChannel
        .receiveBroadcastStream()
        .map((event) {
            final data = HeartRateData.fromJson(Map<String, dynamic>.from(event));
            _autoSyncToPhone(data);   // ← side-effect: also pushes to phone
            return data;
        });
    return _heartRateStream!;
}
```

#### Retry logic
Exponential backoff for `connectToWatch()`. Retryable conditions: `connectionFailed`, `timeout`, `serviceUnavailable`.

---

### 5.4 WatchToPhoneSync

`lib/services/watch_to_phone_sync.dart` — Dart facade over the `com.pulsify.watch/sync` channel.

```dart
Future<bool> sendHeartRateToPhone(HeartRateData data)  // → sendHeartRateToPhone
Future<bool> sendBatchData(List<HeartRateData> list)   // → sendBatchToPhone
Future<bool> checkPhoneConnection()                     // → checkPhoneConnection
Future<int>  getConnectedNodesCount()                   // → getConnectedNodesCount
```

---

### 5.5 PhoneDataListener

`lib/services/phone_data_listener.dart` — Dart facade over the `com.pulsify.phone/*` channels. Used when the app is running **on the phone**, receiving data from the watch over the Data Layer.

```dart
static const MethodChannel _methodChannel       = MethodChannel('com.pulsify.phone/data');
static const EventChannel  _heartRateEventChannel    = EventChannel('com.pulsify.phone/heartrate');
static const EventChannel  _sensorBatchEventChannel  = EventChannel('com.pulsify.phone/sensor_data');
```

#### Streams
```dart
Stream<HeartRateData> get heartRateStream   // validates: timestamp (int), status (String)
Stream<SensorBatch>   get sensorBatchStream // validates: type, timestamp, bpm, count, accelerometer
```

---

### 5.6 HeartRateService

`lib/services/heart_rate_service.dart` — High-level HR processing layer.

- Receives `HeartRateData` from `PhoneDataListener`.
- Maintains: current BPM, max BPM, rolling history, time-in-zone counters.
- Zone definitions (% of max HR): Zone1=50–60%, Zone2=60–70%, Zone3=70–80%, Zone4=80–90%, Zone5=90–100%.
- Exposes `Stream<int> heartRateStream`.

---

### 5.7 HeartRateDataManager

`lib/services/heart_rate_data_manager.dart` — Persistence and analytics layer.

```dart
final int maxBufferSize    = 100;     // flush to SQLite when exceeded
final int maxDatabaseRecords = 10000; // auto-prune oldest entries
```

- **Buffer** → SQLite via `DatabaseService`.
- **IBI history** → `IbiHistoryManager` (rolling window) → `calculateHRV()` using RMSSD formula.
- **DataSyncManager** → periodic Supabase sync every 15 minutes, marks records as synced.

---

## 6. Data Models

### HeartRateData (`lib/models/heart_rate_data.dart`)
```dart
class HeartRateData {
  final int?       bpm;
  final DateTime   timestamp;
  final SensorStatus status;   // enum: active | inactive | error
  final List<int>  ibiValues;  // inter-beat intervals in milliseconds
}
```

### SensorBatch (`lib/models/sensor_batch.dart`)
```dart
// 32 samples: each sample = [accX, accY, accZ, bpm]
// bpm is the SAME single value broadcast to all 32 samples
class SensorBatch {
  final List<List<double>> samples;  // shape: 32 × [accX, accY, accZ, bpm]
  final int timestamp;
}
```

### TrackedData (`lib/models/tracked_data.dart`)
```dart
class TrackedData {
  final int       hr;
  final List<int> ibiValues;
  final double    hrv;       // RMSSD calculated from ibiValues
  final int       spo2;
  final DateTime  timestamp;
  final SensorStatus status;

  static double calculateHRV(List<int> ibiList) {
    // RMSSD = sqrt( mean( (ibi[i+1] - ibi[i])^2 ) )
  }
}
```

---

## 7. AI / Activity Classifier Pipeline

### TFLiteActivityClassifier (`lib/features/activity_classifier/platform/tflite_activity_classifier.dart`)

```
Model: assets/model/activity_tracker.tflite
Input:  [1, 320, 4]   — 320 time steps × [accX, accY, accZ, bpm]
Output: [1, 3]        — [Stress%, Cardio%, Strength%]
```

**REST gate:** If `bpm < 85`, skip inference and return `'Calm'` directly.

```dart
Future<List<double>> predict(List<List<double>> buffer) async {
    // buffer.length MUST == 320 — no padding/truncation
    final input  = [buffer];
    final output = List.filled(3, 0.0).reshape([1, 3]);
    _interpreter!.run(input, output);
    return List<double>.from(output[0] as List);
}
```

### HeartBpmAdapter (`lib/features/activity_classifier/platform/heart_bpm_adapter.dart`)

Unified BPM source abstraction. Accepts:
- External `Stream<int>` (watch, `heart_bpm` plugin)
- Manual injection (for testing)

### tracker_page.dart — Data Source Selector

**Accelerometer sources:**
| Source | Implementation |
|---|---|
| `AccelSource.Phone` | `sensors_plus` — phone's own accelerometer |
| `AccelSource.Simulation` | Synthetic sinusoidal signal at ~32 Hz |
| `AccelSource.Watch` | `PhoneDataListener.sensorBatchStream` — 32-sample batches from Galaxy Watch |

**Heart Rate sources:**
| Source | Implementation |
|---|---|
| `BpmSource.Simulation` | Slider — 60–180 BPM |
| `BpmSource.Plugin` | `heart_bpm` — camera-based optical HR |
| `BpmSource.Watch` | `PhoneDataListener.heartRateStream` — from Galaxy Watch |

**Inference:** Incoming samples are appended to a 320-sample sliding window buffer. When full, `TFLiteActivityClassifier.predict()` is called and results are displayed in real time.

---

## 8. Platform Channel Registry

### MethodChannels

| Channel | Methods | Direction |
|---|---|---|
| `com.pulsify.watch/data` | `requestPermission`, `checkPermission`, `connectWatch`, `disconnectWatch`, `isWatchConnected`, `startHeartRate`, `stopHeartRate`, `getCurrentHeartRate`, `getTestModeData` | Dart → Kotlin (watch side) |
| `com.pulsify.watch/sync` | `sendHeartRateToPhone`, `sendBatchToPhone`, `checkPhoneConnection`, `getConnectedNodesCount` | Dart → Kotlin (watch side) |
| `com.pulsify.phone/data` | `startListening`, `stopListening`, `isWatchConnected` | Dart → Kotlin (phone side) |
| `com.pulsify.geofence/native` | `registerGeofence`, `unregisterGeofence` | Dart → Kotlin |

### EventChannels

| Channel | Payload | Direction | Source |
|---|---|---|---|
| `com.pulsify.watch/heartrate` | `{bpm, ibiValues, timestamp, status}` | Native → Dart | Samsung Health SDK |
| `com.pulsify.watch/transmission` | `{timestamp}` | Native → Dart | Fires on each sensor batch transmission |
| `com.pulsify.phone/heartrate` | `HeartRateData` map | Native → Dart | `PhoneDataListenerService` |
| `com.pulsify.phone/sensor_data` | `SensorBatch` map | Native → Dart | `PhoneDataListenerService` |
| `com.pulsify.geofence/events` | `{event, geofenceId}` | Native → Dart | Stubbed |

### Wearable Data Layer Message Paths

| Path | JSON Payload | Direction |
|---|---|---|
| `/heart_rate` | `HeartRateData` JSON | Watch → Phone |
| `/heart_rate_batch` | `TrackedData[]` JSON | Watch → Phone |
| `/sensor_data` | `SensorBatch` JSON | Watch → Phone |

---

## 9. Samsung Health SDK Details

**Location:** `android/app/libs/samsung-health-sensor-api-1.4.1.aar` (local file dependency — NOT on Maven Central).

Must be manually downloaded from [Samsung Developers](https://developer.samsung.com/health/galaxy-watch/overview.html).

### Key SDK Classes
| Class | Role |
|---|---|
| `HealthTrackingService` | Entry point — connect with `ConnectionListener`, call `connectService()` |
| `HealthTracker` | Individual sensor instance — set via `setEventListener()` |
| `ConnectionListener` | `onConnectionSuccess()`, `onConnectionEnded()`, `onConnectionFailed()` |
| `HealthTrackerType.HEART_RATE_CONTINUOUS` | Continuous HR tracking type |
| `ValueKey.HeartRateSet.HEART_RATE` | `Int` — BPM value |
| `ValueKey.HeartRateSet.HEART_RATE_STATUS` | `Int` — `1` = valid, else invalid |
| `ValueKey.HeartRateSet.IBI_LIST` | `IntArray` — inter-beat intervals (ms) |
| `ValueKey.HeartRateSet.IBI_STATUS_LIST` | `IntArray` — `0` = valid per IBI entry |

---

## 10. Critical Design Notes

1. **`applicationContext` for `HealthTrackingService`** — Using activity context causes the service to die when the screen turns off. `HealthTrackingManager` correctly receives `context.applicationContext` from `MainActivity`.

2. **Capability check inside `onConnectionSuccess()` only** — Calling `healthTrackingService.trackingCapability` before connection is fully established will throw. It MUST be checked inside the `onConnectionSuccess` callback.

3. **All `EventSink` calls must be on the main thread** — The Samsung Health SDK delivers callbacks on its own thread. All `eventSink?.success(...)` calls are wrapped with `mainHandler.post { }`.

4. **Static `EventSink` in `PhoneDataListenerService`** — `WearableListenerService` is started by the OS in a separate process/lifecycle from `MainActivity`. Using `companion object` static fields allows `MainActivity` to inject the Flutter `EventSink` after the engine is initialized.

5. **`minSdk = 30`** — Required for Samsung Health Sensor API and Wear OS 3. This means the phone companion app also requires Android 11+ — limiting the potential phone user base.

6. **REST gate before TFLite** — If `bpm < 85`, the model is skipped and `'Calm'` is returned directly to avoid false positives during rest.

7. **`wear.xml` capability advertisement** — The phone app needs a `res/xml/wear.xml` with `<uses-feature android:name="pulsify_phone_app" />` registered via `<meta-data>` in the phone manifest. Without it, `CapabilityClient.getCapability("pulsify_phone_app")` will always return an empty set.

---

## 11. Possible Issues & Bugs

### 🔴 Critical

---

**Issue 1: `<uses-feature android:name="android.hardware.type.watch" />` in main manifest**

The `AndroidManifest.xml` declares `android.hardware.type.watch` as a feature. This tells Google Play that this APK is a **Wear OS / watch app**. It will NOT appear in the Play Store for phone users.

If this manifest is also used for the phone build, the phone companion app will be invisible to phone users. The watch and phone builds need **separate manifests** (or a split-module/product-flavor setup).

---

**Issue 2: `wear.xml` capability file missing on phone side**

`WatchToPhoneSyncManager` discovers the phone by querying `CapabilityClient.getCapability("pulsify_phone_app", FILTER_REACHABLE)`. This requires the phone app to advertise `pulsify_phone_app` in `res/xml/wear.xml`:

```xml
<!-- android/app/src/main/res/xml/wear.xml (on PHONE) -->
<wearable-app>
    <uses-feature android:name="pulsify_phone_app" />
</wearable-app>
```

And referenced in the phone's `AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.wearable.application"
           android:resource="@xml/wear" />
```

**Without this, capability-based discovery always fails, and only the fallback (all connected nodes) is used.** In a multi-device household this can route data to the wrong device.

---

**Issue 3: `PhoneDataListenerService` — Background Activity Launch Blocked on Android 10+**

When `eventSink == null` and a `/heart_rate` message arrives, the service calls:
```kotlin
startActivity(Intent(this, MainActivity::class.java).apply {
    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    putExtra("heart_rate_data", data)
})
```
Android 10 (API 29)+ **blocks background activity launches** from services unless `SYSTEM_ALERT_WINDOW` is granted or the app is in the foreground. This call will **silently fail** on modern Android. A foreground notification with a `PendingIntent` should be used instead.

---

**Issue 4: `/heart_rate_batch` path not registered in `PhoneDataListenerService` intent-filter**

The manifest registers `PhoneDataListenerService` for `/heart_rate` and `/sensor_data`:
```xml
<data android:pathPrefix="/heart_rate"  android:scheme="wear" />
<data android:pathPrefix="/sensor_data" android:scheme="wear" />
```
But `WatchToPhoneSyncManager.sendBatchToPhone()` sends to `/heart_rate_batch`. This path is NOT registered, so these messages will **never trigger `PhoneDataListenerService`** and will be silently dropped.

---

### 🟠 High Severity

---

**Issue 5: Single APK for both Watch and Phone roles**

The current code has:
- Samsung Health SDK code → intended for the **watch**
- `PhoneDataListenerService` → intended for the **phone**
- Both are compiled into the **same APK**

A single APK cannot properly serve as both the watch app and the phone companion simultaneously. The standard approach is:
- A **watch module** (Wear OS) with the Samsung Health / sensor code
- A **phone module** (standard Android) with the listener service

Without this split, deploying on a watch means the phone listener code is also running there (and vice versa), leading to unexpected behavior and wasted resources.

---

**Issue 6: Coroutine scope leaks**

Both `MainActivity` and `WatchToPhoneSyncManager` create `CoroutineScope` instances that are **never cancelled**:
```kotlin
// MainActivity
private val scope = CoroutineScope(Dispatchers.Main)

// WatchToPhoneSyncManager
private val scope = CoroutineScope(Dispatchers.IO)
```
These leak coroutines when the activity is destroyed. `MainActivity.scope` should be a `lifecycleScope` (or manually cancelled in `onDestroy()`). `WatchToPhoneSyncManager.scope` should be a `SupervisorScope` that is cancelled when the manager is disposed.

---

**Issue 7: No reconnection logic if Samsung Health service drops**

`HealthTrackingManager.connectionListener.onConnectionEnded()` sets `healthTrackingService = null` and fires the callback with `false` — but there is **no automatic reconnection**. During a workout, if the Samsung Health service temporarily drops, the Dart side would need to call `connectWatch` again. There is no retry or reconnect strategy wired up.

---

**Issue 8: Accelerometer sample rate mismatch — `SENSOR_DELAY_GAME` ≠ 32 Hz**

```kotlin
sensorManager.registerListener(accelListener, accelerometer, SensorManager.SENSOR_DELAY_GAME)
```
`SENSOR_DELAY_GAME` targets ~50 Hz, not 32 Hz. The actual rate is device-dependent. The TFLite model expects `[accX, accY, accZ, bpm]` at **exactly 32 Hz** over 320 samples (10 seconds of data). If the actual sample rate is 50 Hz, 320 samples = only ~6.4 seconds, distorting the temporal features the model learned. A proper fixed-rate sampling strategy (using `SENSOR_DELAY_FASTEST` with explicit rate limiting, or Android's `SensorManager.registerListener` with the `samplingPeriodUs` parameter for API 22+) should be used.

---

**Issue 9: BPM broadcast to all 32 accelerometer samples**

In `SensorBatch.fromJson()` (Dart model):
```
// broadcasts same bpm to all 32 samples: [accX, accY, accZ, bpm]
```
The BPM is a **single snapshot** captured at the moment the batch is assembled, but it is replicated into all 32 sample slots as if it were sampled at 32 Hz. If the model was trained with interpolated or genuinely sampled BPM data at 32 Hz, this broadcast strategy will produce a very different input distribution and degrade prediction accuracy.

---

**Issue 10: `accelBuffer` drops samples when rate exceeds 32 Hz**

```kotlin
if (accelBuffer.size < BUFFER_SIZE) accelBuffer.add(reading)
```
When the sensor fires at ~50 Hz, the buffer fills to 32 in ~640ms. After that, **all new readings are silently ignored** until the buffer is cleared in `sendBatchToPhone()`. This means the 32-sample batch always represents the **first 640ms** of each second, not a uniform 1-second window. The 10 batches making up a 320-sample window would not be evenly spaced over time.

---

### 🟡 Medium Severity

---

**Issue 11: Static `EventSink` race condition in `PhoneDataListenerService`**

`PhoneDataListenerService` is started by the OS as a separate process when a Data Layer message arrives. `MainActivity` sets `PhoneDataListenerService.eventSink` in `configureFlutterEngine()`. If a message arrives **before** `MainActivity` creates the Flutter engine, `eventSink` is null and the data is dropped (with the flawed `launchMainActivity()` fallback — see Issue 3). There is no queuing mechanism for missed messages.

---

**Issue 12: `SensorTrackingService` foreground service type not verified**

`SensorTrackingService` is declared in the manifest with `foregroundServiceType="health"`. On Android 12+, a foreground service with `type="health"` **must** call `startForeground(id, notification, FOREGROUND_SERVICE_TYPE_HEALTH)`. If `SensorTrackingService` calls `startForeground()` without the type argument, it will throw a `ForegroundServiceTypeException` on Android 14+. The service implementation was not present in the code reviewed — this needs verification.

---

**Issue 13: `minSdk = 30` applied to the phone module**

`minSdk = 30` (Android 11) is required for the Samsung Health Sensor API on the **watch**, but it also applies to the **phone** app in a single-module setup. This unnecessarily excludes phone users on Android 10 (API 29) and below from installing the companion app.

---

**Issue 14: IBI data unreliable during exercise**

The Samsung Health Sensor API only provides reliable IBI (inter-beat interval) data during resting or low-activity periods. During high-intensity exercise (the primary Pulsify use case), the IBI arrays may frequently be empty or flagged as invalid (`IBI_STATUS_LIST` entries ≠ 0). This means:
- RMSSD-based HRV will be unavailable or based on sparse data during workouts.
- The `Calm` mode determination (bpm < 85 + IBI analysis) may not be accurate.

---

**Issue 15: No wake lock lifecycle management in background service**

The wake lock is acquired in `MainActivity` with a 10-minute TTL. If tracking continues beyond 10 minutes, the lock expires and the watch screen/CPU may be suspended, interrupting the Samsung Health SDK data stream. The wake lock acquisition should occur in `SensorTrackingService` (a foreground service) rather than in the activity.

---

**Issue 16: Samsung Health AAR build failure if file is missing**

```kotlin
implementation(files("libs/samsung-health-sensor-api-1.4.1.aar"))
```
If the AAR file is not present (e.g., after a fresh `git clone`), the build will **fail immediately** with a confusing Gradle error. There is no graceful fallback or helpful error message. The README / setup docs should prominently document how to obtain and place this file, and CI should handle its absence cleanly.

---

**Issue 17: `heartRateStream` side-effect auto-sync**

In `WatchBridgeService.heartRateStream`:
```dart
_autoSyncToPhone(heartRateData);  // ← called on every HR event
```
This silently triggers a network call (via `WatchToPhoneSync`) on every heart rate event. If the phone is disconnected, this will spam error logs. More importantly, it is a **hidden side effect** on a getter — callers who just want to observe the stream are also unintentionally triggering sync operations.

---

**Issue 18: RMSSD calculation with very few IBI samples**

`IbiHistoryManager.calculateHRV()` divides by `(n - 1)` successive differences. If only 1 or 2 IBI values arrive per event (common during exercise), the HRV value is statistically meaningless and potentially `NaN` or `Infinity`. The calculation should require a minimum window (e.g., ≥ 5 successive differences) before returning a result.

---

### 🟢 Low Severity / Code Quality

---

**Issue 19: Kotlin serialization plugin version mismatch**

```kotlin
id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"  // in app/build.gradle.kts
id("org.jetbrains.kotlin.android")               version "2.1.0"  // in settings.gradle.kts
```
The serialization plugin (`1.9.0`) should match the Kotlin version (`2.1.0`). Using a mismatched plugin version can cause subtle serialization issues or build warnings that graduate into errors in future Kotlin releases.

---

**Issue 20: `wearable_rotary` plugin imported for Galaxy Watch bezel — not for phone**

`WearableRotaryPlugin` is registered in `MainActivity.configureFlutterEngine()`. This plugin handles Galaxy Watch's rotating bezel input. It has **no effect on the phone** and will throw or log harmless errors if not used on a Wear OS device. It should only be registered when building the watch target.

---

**Issue 21: `healthTrackingManager` is initialized in `onCreate()` regardless of role**

`HealthTrackingManager` (Samsung Health SDK) is initialized on every `MainActivity` startup — even when the app is running as the phone companion. On the phone, the Samsung Health library is present in the APK but there is no Galaxy Watch sensor hardware; attempting to connect will always fail. The initialization should be gated (e.g., only when a `isWatchBuild` flag is set).

---

## Summary Table

| # | Severity | Issue |
|---|---|---|
| 1 | 🔴 Critical | `uses-feature watch` makes APK invisible to phone Play Store users |
| 2 | 🔴 Critical | `wear.xml` capability file missing — watch-to-phone discovery always falls back |
| 3 | 🔴 Critical | Background activity launch from service blocked on Android 10+ |
| 4 | 🔴 Critical | `/heart_rate_batch` path not registered in manifest — batches are silently dropped |
| 5 | 🟠 High | Single APK for both watch and phone roles — architectural confusion |
| 6 | 🟠 High | Coroutine scope leaks in `MainActivity` and `WatchToPhoneSyncManager` |
| 7 | 🟠 High | No reconnection logic if Samsung Health service disconnects mid-workout |
| 8 | 🟠 High | `SENSOR_DELAY_GAME` ≠ 32 Hz — model input temporal frequency is wrong |
| 9 | 🟠 High | BPM broadcast to all 32 accel samples — incorrect model input |
| 10 | 🟠 High | Accel buffer drops samples at rates > 32 Hz — uneven time windows |
| 11 | 🟡 Medium | Static `EventSink` race condition if OS starts service before Flutter engine |
| 12 | 🟡 Medium | `SensorTrackingService` foreground type argument may be missing — crash on Android 14+ |
| 13 | 🟡 Medium | `minSdk = 30` unnecessarily restricts phone companion users |
| 14 | 🟡 Medium | IBI data unreliable during exercise — HRV / Calm mode degraded |
| 15 | 🟡 Medium | Wake lock held in activity, not foreground service — may expire mid-workout |
| 16 | 🟡 Medium | Build fails with no helpful message if Samsung Health AAR is missing |
| 17 | 🟡 Medium | Hidden auto-sync side-effect in `heartRateStream` getter |
| 18 | 🟡 Medium | RMSSD calculated with too few IBI samples — potentially NaN/meaningless |
| 19 | 🟢 Low | Kotlin serialization plugin version doesn't match Kotlin version |
| 20 | 🟢 Low | `WearableRotaryPlugin` registered on phone builds unnecessarily |
| 21 | 🟢 Low | `HealthTrackingManager` initialized on phone side where it will always fail |
