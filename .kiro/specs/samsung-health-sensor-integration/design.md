# Design Document: Samsung Health Sensor Integration

## Overview

This design document outlines the technical architecture for integrating Samsung Health Sensor API into the Pulsify Flutter application for Galaxy Watch 6 (Wear OS). The integration follows a layered architecture with clear separation between Flutter (Dart) and native Android (Kotlin) code, connected via Flutter's Method Channel mechanism.

The solution enables real-time biometric data collection from Samsung Galaxy Watch sensors, with proper permission handling, lifecycle management, and error handling throughout the stack.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GALAXY WATCH (Wear OS)                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                  Flutter Layer (Dart)                         │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │   UI Components & Screens                               │  │  │
│  │  └───────────────┬─────────────────────────────────────────┘  │  │
│  │                  │                                             │  │
│  │  ┌───────────────▼─────────────────────────────────────────┐  │  │
│  │  │   WatchBridgeService                                    │  │  │
│  │  │   - Permission Management                               │  │  │
│  │  │   - Sensor Data Streams                                 │  │  │
│  │  │   - Watch-to-Phone Sync                                 │  │  │
│  │  └───────────────┬─────────────────────────────────────────┘  │  │
│  └──────────────────┼─────────────────────────────────────────────┘  │
│                     │ Method Channel                                 │
│  ┌──────────────────▼─────────────────────────────────────────────┐  │
│  │            Native Android Layer (Kotlin)                       │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │   MainActivity (Watch)                                  │   │  │
│  │  │   - Method Channel Handler                              │   │  │
│  │  └───────────────┬─────────────────────────────────────────┘   │  │
│  │                  │                                              │  │
│  │  ┌───────────────▼─────────────────────────────────────────┐   │  │
│  │  │   HealthTrackingManager                                 │   │  │
│  │  │   - Connection Management                               │   │  │
│  │  │   - Sensor Listeners                                    │   │  │
│  │  │   - Lifecycle Handling                                  │   │  │
│  │  └───────────────┬─────────────────────────────────────────┘   │  │
│  │                  │                                              │  │
│  │  ┌───────────────▼─────────────────────────────────────────┐   │  │
│  │  │   WatchToPhoneSyncManager                               │   │  │
│  │  │   - MessageClient API                                   │   │  │
│  │  │   - CapabilityClient (Node Discovery)                   │   │  │
│  │  │   - JSON Encoding                                       │   │  │
│  │  └───────────────┬─────────────────────────────────────────┘   │  │
│  └──────────────────┼──────────────────────────────────────────────┘  │
└────────────────────┼──────────────────────────────────────────────────┘
                     │
                     │ Wearable Data Layer API
                     │ (MessageClient)
                     │ Path: "/heart_rate"
                     │
┌────────────────────▼──────────────────────────────────────────────────┐
│                    ANDROID PHONE (Companion)                          │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │            Native Android Layer (Kotlin)                         │ │
│  │  ┌────────────────────────────────────────────────────────────┐  │ │
│  │  │   PhoneDataListenerService                                 │  │ │
│  │  │   - Extends WearableListenerService                        │  │ │
│  │  │   - Declared in AndroidManifest.xml                        │  │ │
│  │  │   - Listens for MESSAGE_RECEIVED intent                    │  │ │
│  │  │   - Filters path: "/heart_rate"                            │  │ │
│  │  └───────────────┬────────────────────────────────────────────┘  │ │
│  └──────────────────┼──────────────────────────────────────────────── │
│                     │ Event Channel                                   │
│  ┌──────────────────▼──────────────────────────────────────────────┐ │
│  │                  Flutter Layer (Dart)                           │ │
│  │  ┌────────────────────────────────────────────────────────────┐ │ │
│  │  │   MainActivity (Phone)                                     │ │ │
│  │  │   - Receives Intent with heart rate data                   │ │ │
│  │  │   - Event Channel for streaming                            │ │ │
│  │  └───────────────┬────────────────────────────────────────────┘ │ │
│  │                  │                                               │ │
│  │  ┌───────────────▼────────────────────────────────────────────┐ │ │
│  │  │   PhoneDataService                                         │ │ │
│  │  │   - Decodes JSON to HeartRateData                          │ │ │
│  │  │   - Updates UI with BPM & IBI values                       │ │ │
│  │  └────────────────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│   Samsung Health Sensor API (Watch Only)    │
│   - Heart Rate Sensor                       │
│   - Accelerometer                           │
│   - Other Biometric Sensors                 │
└─────────────────────────────────────────────┘
```

### Technology Stack

- **Flutter SDK**: 3.x (Dart)
- **Android**: Kotlin, Gradle 8.x
- **Samsung Health Sensor API**: 1.4.1 (AAR)
- **AndroidX Health Services**: Latest stable
- **Method Channel**: Flutter platform channel for native communication
- **Minimum SDK**: Android API 30 (Wear OS 3.0+)

## Components and Interfaces

### 1. Flutter Layer Components

#### WatchBridgeService (Dart)

Primary service class for managing watch sensor communication from Flutter.

```dart
class WatchBridgeService {
  static const MethodChannel _channel = MethodChannel('com.pulsify.watch/data');
  
  // Permission management
  Future<bool> requestBodySensorPermission();
  Future<PermissionStatus> checkBodySensorPermission();
  
  // Connection management
  Future<bool> connectToWatch();
  Future<void> disconnectFromWatch();
  Future<bool> isWatchConnected();
  
  // Sensor data access
  Stream<HeartRateData> get heartRateStream;
  Future<HeartRateData?> getCurrentHeartRate();
  
  // Lifecycle
  Future<void> startHeartRateTracking();
  Future<void> stopHeartRateTracking();
}
```

#### Data Models

```dart
class HeartRateData {
  final int bpm;
  final DateTime timestamp;
  final SensorStatus status;
}

class TrackedData {
  final int hr;
  final List<int> ibi;
  
  TrackedData({required this.hr, required this.ibi});
  
  factory TrackedData.fromJson(Map<String, dynamic> json) {
    return TrackedData(
      hr: json['hr'] ?? 0,
      ibi: List<int>.from(json['ibi'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {'hr': hr, 'ibi': ibi};
  }
}

enum SensorStatus {
  active,
  inactive,
  error,
  unavailable
}

enum PermissionStatus {
  granted,
  denied,
  notDetermined
}
```

### 2. Native Android Layer Components (Watch)

#### MainActivity (Kotlin) - Watch

Enhanced to handle Method Channel calls and route to HealthTrackingManager and WatchToPhoneSyncManager.

```kotlin
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.pulsify.watch/data"
    private lateinit var healthManager: SamsungHealthManager
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        healthManager = SamsungHealthManager(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
    }
    
    private fun handleMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "checkPermission" -> checkPermission(result)
            "connectWatch" -> connectWatch(result)
            "disconnectWatch" -> disconnectWatch(result)
            "startHeartRate" -> startHeartRateTracking(result)
            "stopHeartRate" -> stopHeartRateTracking(result)
            "getCurrentHeartRate" -> getCurrentHeartRate(result)
            "sendBatchToPhone" -> sendBatchToPhone(result)
            else -> result.notImplemented()
        }
    }
    
    private fun requestPermission(result: Result) {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            "android.permission.health.READ_HEART_RATE"
        } else {
            Manifest.permission.BODY_SENSORS
        }
        // Request appropriate permission based on Android version
    }
    
    private fun sendBatchToPhone(result: Result) {
        val data = healthManager.getValidHrData()
        val json = Json.encodeToString(data)
        syncManager.sendBatchToPhone(json) { success ->
            result.success(success)
        }
    }
}
```

#### TrackedData (Kotlin) - Watch

Data class for heart rate measurements with IBI values.

```kotlin
@Serializable
data class TrackedData(
    var hr: Int = 0,
    var ibi: ArrayList<Int> = ArrayList()
)
```

#### HealthTrackingManager (Kotlin) - Watch

Core manager for Samsung Health Sensor API integration with data validation and batch collection.

```kotlin
class HealthTrackingManager(
    private val context: Context,
    private val onHeartRateData: (HeartRateData) -> Unit,
    private val onError: (String, String?) -> Unit
) {
    private var healthTrackingService: HealthTrackingService? = null
    private var heartRateTracker: HealthTracker? = null
    private var isTracking: Boolean = false
    private var isServiceConnected: Boolean = false
    
    // Data collection
    private val validHrData = ArrayList<TrackedData>()
    private val maxDataPoints = 40
    
    // Connection management
    fun connect(callback: (Boolean, String?) -> Unit)
    fun disconnect()
    fun isConnected(): Boolean
    
    // Heart rate tracking
    fun startTracking(): Boolean
    fun stopTracking()
    
    // Data validation
    private fun isHRValid(status: Int): Boolean
    private fun getValidIbiList(dataPoint: DataPoint): List<Int>
    
    // Batch data management
    fun getValidHrData(): ArrayList<TrackedData>
    private fun trimDataList()
    
    // Lifecycle
    fun onResume()
    fun onPause()
    fun onDestroy()
}
```

#### WatchToPhoneSyncManager (Kotlin) - Watch

Manages data synchronization from watch to phone using Wearable Data Layer API.

```kotlin
class WatchToPhoneSyncManager(private val context: Context) {
    private val messageClient: MessageClient
    private val capabilityClient: CapabilityClient
    private val nodeClient: NodeClient
    
    // Data transmission
    fun sendHeartRateToPhone(jsonData: String, callback: (Boolean) -> Unit)
    fun sendBatchToPhone(jsonData: String, callback: (Boolean) -> Unit)
    
    // Connection management
    suspend fun checkPhoneConnection(): Boolean
    suspend fun getConnectedNodesCount(): Int
    suspend fun findPhoneNode(): Node?
    
    // Node discovery
    private suspend fun getConnectedNodes(): List<Node>
    private suspend fun getCapableNodes(): Set<Node>
}
```

### 3. Native Android Layer Components (Phone)

#### PhoneDataListenerService (Kotlin) - Phone

Service that receives heart rate data from the watch via Wearable Data Layer.

```kotlin
class PhoneDataListenerService : WearableListenerService() {
    companion object {
        private const val MESSAGE_PATH = "/heart_rate"
        var eventSink: EventChannel.EventSink? = null
    }
    
    override fun onMessageReceived(messageEvent: MessageEvent) {
        // Handle incoming messages from watch
        // Decode JSON and forward to Flutter via EventChannel
    }
    
    private fun handleHeartRateData(messageEvent: MessageEvent)
    private fun launchMainActivity(data: String)
}
```

#### MainActivity (Kotlin) - Phone

Handles EventChannel setup for receiving watch data in Flutter.

```kotlin
class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Set up EventChannel for phone data listener
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pulsify.phone/heartrate")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    PhoneDataListenerService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    PhoneDataListenerService.eventSink = null
                }
            })
    }
}
```

### 4. Method Channel Protocol

#### Method Calls (Flutter → Android) - Watch Side

**Channel:** `com.pulsify.watch/data`

| Method | Arguments | Return Type | Description |
|--------|-----------|-------------|-------------|
| `requestPermission` | None | `bool` | Request BODY_SENSORS permission |
| `checkPermission` | None | `String` | Check permission status |
| `connectWatch` | None | `bool` | Connect to Samsung Health |
| `disconnectWatch` | None | `void` | Disconnect from Samsung Health |
| `startHeartRate` | None | `bool` | Start heart rate tracking |
| `stopHeartRate` | None | `void` | Stop heart rate tracking |
| `getCurrentHeartRate` | None | `Map` | Get latest heart rate data |

**Channel:** `com.pulsify.watch/sync`

| Method | Arguments | Return Type | Description |
|--------|-----------|-------------|-------------|
| `sendHeartRateToPhone` | `data: String` (JSON) | `bool` | Send heart rate data to phone |
| `sendBatchToPhone` | `data: String` (JSON) | `bool` | Send batch data to phone |
| `checkPhoneConnection` | None | `bool` | Check if phone is connected |
| `getConnectedNodesCount` | None | `int` | Get count of connected nodes |

#### Event Channels (Android → Flutter)

**Watch Side:**

| Channel | Data Type | Description |
|---------|-----------|-------------|
| `com.pulsify.watch/heartrate` | `Map<String, dynamic>` | Stream of heart rate updates from sensor |

**Phone Side:**

| Channel | Data Type | Description |
|---------|-----------|-------------|
| `com.pulsify.phone/heartrate` | `String` (JSON) | Stream of heart rate data received from watch |

## Data Models

### HeartRateData (Watch Sensor)

```dart
{
  "bpm": int?,          // Beats per minute (null if invalid)
  "ibiValues": List<int>, // Inter-beat intervals in milliseconds
  "timestamp": int,     // Unix timestamp in milliseconds
  "status": String      // "active", "inactive", "error", "unavailable"
}
```

### Watch-to-Phone Message Format

**Message Path:** `/heart_rate`

**JSON Payload:**
```json
{
  "bpm": 72,
  "ibiValues": [850, 845, 855, 848],
  "timestamp": 1732507200000,
  "status": "active"
}
```

**Key Requirements:**
- Must use exact path `/heart_rate` (not `/heart_rate_data`)
- JSON encoding for extensibility
- ibiValues array contains valid IBI measurements in milliseconds
- status indicates data quality

### ConnectionStatus

```dart
{
  "connected": bool,
  "deviceName": String?,
  "error": String?
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Permission state determines sensor availability
*For any* permission state (granted or denied), the sensor data collection features should be enabled if and only if the permission is granted.
**Validates: Requirements 3.2, 3.3**

### Property 2: Permission check is idempotent
*For any* current permission state, checking the permission status should return that state without triggering a permission request dialog or changing the state.
**Validates: Requirements 3.5**

### Property 3: UI reflects permission state
*For any* permission state change, the UI should update to display the current permission status accurately.
**Validates: Requirements 3.4**

### Property 4: Method channel routes to correct handler
*For any* valid method name in the defined protocol, invoking it through the method channel should route to the corresponding native Android handler.
**Validates: Requirements 4.1**

### Property 5: Method channel round-trip
*For any* method call that completes successfully in native code, the result should be returned to the Flutter layer without data loss.
**Validates: Requirements 4.2**

### Property 6: Error propagation
*For any* error that occurs in native Android code, the error should be propagated to Flutter with descriptive error information.
**Validates: Requirements 4.3**

### Property 7: Service availability check on startup
*For any* application startup, the system should check if Samsung Health services are available before attempting connection.
**Validates: Requirements 5.1**

### Property 8: Connection establishes when services available
*For any* device state where Samsung Health services are available, attempting to connect should successfully establish a connection.
**Validates: Requirements 5.2**

### Property 9: Sensor support verification after connection
*For any* successful connection to Samsung Health services, the system should verify that required sensors are supported.
**Validates: Requirements 5.3**

### Property 10: Connection failure provides error information
*For any* connection failure, the system should provide descriptive error information to the caller.
**Validates: Requirements 5.4**

### Property 11: Disconnect on application close
*For any* active Samsung Health connection, closing the application should properly disconnect and release resources.
**Validates: Requirements 5.5**

### Property 12: Tracking lifecycle consistency
*For any* heart rate tracking session, starting tracking should begin data flow, and stopping tracking should cease data flow and release resources.
**Validates: Requirements 6.1, 6.3**

### Property 13: Sensor unavailability handling
*For any* sensor unavailable state, the system should handle the error gracefully and notify the user appropriately.
**Validates: Requirements 6.4**

### Property 14: Background pause behavior
*For any* application transition to background, non-critical sensor tracking should pause.
**Validates: Requirements 7.1**

### Property 15: Foreground resume behavior
*For any* application transition to foreground where tracking was previously active, sensor tracking should resume.
**Validates: Requirements 7.2**

### Property 16: Foreground service during active tracking
*For any* active sensor tracking session, the application should run as a foreground service with a visible notification.
**Validates: Requirements 7.3**

### Property 17: Service cleanup on tracking stop
*For any* state where all tracking is stopped, the foreground service should stop and the notification should be removed.
**Validates: Requirements 7.4**

### Property 18: Watch data transmission to phone
*For any* heart rate data collected on the watch, when a phone node is available, the data should be successfully transmitted to the phone via the Wearable Data Layer.
**Validates: Requirements 8.1**

### Property 19: Phone receives watch data timely
*For any* heart rate data sent from the watch, when received by the phone, it should be delivered to the Flutter layer within 2 seconds.
**Validates: Requirements 8.2**

### Property 20: Node discovery via capability
*For any* attempt to send data from watch to phone, the system should use CapabilityClient to discover connected phone nodes rather than hardcoded node IDs.
**Validates: Requirements 8.3**

### Property 21: Graceful handling of no phone connection
*For any* state where no phone nodes are available, attempting to send data should handle the error gracefully without crashing.
**Validates: Requirements 8.4**

### Property 22: Phone app launch on data reception
*For any* heart rate data received by the phone when the app is not running, the system should launch the phone app.
**Validates: Requirements 8.5**

### Property 23: Consistent message path usage
*For any* heart rate data transmission from watch to phone, the message path should be exactly "/heart_rate".
**Validates: Requirements 9.1**

### Property 24: JSON encoding consistency
*For any* heart rate data encoded for transmission, the JSON should contain bpm, ibiValues, timestamp, and status fields.
**Validates: Requirements 9.2**

### Property 25: Message path filtering on phone
*For any* message received by the phone, only messages with path "/heart_rate" should be processed as heart rate data.
**Validates: Requirements 9.3**

### Property 26: JSON decoding validation
*For any* JSON data received on the phone, the system should validate that required fields (bpm, ibiValues, timestamp, status) are present before processing.
**Validates: Requirements 9.4**

### Property 27: Transmission error logging
*For any* message transmission failure, the system should log the error with descriptive information including node ID and error message.
**Validates: Requirements 9.5**

### Property 28: Android version-aware permission request
*For any* device running Android 15 or higher, requesting sensor permission should request health.READ_HEART_RATE, and for Android 14 or lower, should request BODY_SENSORS.
**Validates: Requirements 10.1, 10.2**

### Property 29: Heart rate status validation
*For any* heart rate measurement received, only measurements with valid status indicators should be stored in the data collection.
**Validates: Requirements 11.1, 11.2**

### Property 30: IBI status filtering
*For any* IBI values received, only IBI measurements with valid status indicators should be included in the TrackedData.
**Validates: Requirements 11.3**

### Property 31: Data collection size limit
*For any* data collection containing more than 40 measurements, adding a new measurement should remove the oldest measurement to maintain the limit.
**Validates: Requirements 12.2**

### Property 32: Batch data encoding
*For any* batch send operation, all stored TrackedData measurements should be encoded as a JSON array.
**Validates: Requirements 12.4**

### Property 33: TrackedData serialization round-trip
*For any* TrackedData object, serializing to JSON and then deserializing should produce an equivalent object with the same hr and ibi values.
**Validates: Requirements 13.1, 13.2, 13.3**

### Property 34: Phone UI displays received data
*For any* heart rate data received by the phone, the UI should display both the BPM value and IBI measurements.
**Validates: Requirements 14.2, 14.3**

## Error Handling

### Error Categories

1. **Permission Errors**
   - User denies permission
   - Permission revoked during operation
   - Handling: Disable sensor features, show user-friendly message, provide settings link

2. **Connection Errors**
   - Samsung Health services not available
   - Connection timeout
   - Service disconnected unexpectedly
   - Handling: Retry logic with exponential backoff, fallback to cached data, user notification

3. **Sensor Errors**
   - Sensor not supported on device
   - Sensor hardware failure
   - Data read timeout
   - Handling: Graceful degradation, error logging, user notification

4. **Method Channel Errors**
   - Method not implemented
   - Invalid arguments
   - Native exception
   - Handling: Proper error codes, descriptive messages, Flutter-side error handling

### Error Response Format

```dart
class SensorError {
  final SensorErrorCode code;
  final String message;
  final String? details;
  final DateTime timestamp;
}

enum SensorErrorCode {
  permissionDenied,
  serviceUnavailable,
  connectionFailed,
  sensorNotSupported,
  sensorUnavailable,
  timeout,
  unknown
}
```

## Testing Strategy

### Unit Testing

Unit tests will cover:
- WatchBridgeService method behavior with mocked method channels
- Data model serialization/deserialization
- Permission state management logic
- Error handling and error object creation
- SamsungHealthManager connection state management

### Property-Based Testing

We will use the **test** package with **faker** for property-based testing in Dart. For Kotlin, we will use **Kotest** with property testing support.

Each property-based test will:
- Run a minimum of 100 iterations
- Generate random valid inputs for the property being tested
- Verify the property holds across all generated inputs
- Be tagged with a comment referencing the design document property

Example property test structure:

```dart
// Feature: samsung-health-sensor-integration, Property 2: Permission check is idempotent
test('permission check should be idempotent', () async {
  for (var i = 0; i < 100; i++) {
    final initialState = randomPermissionState();
    final firstCheck = await service.checkPermission();
    final secondCheck = await service.checkPermission();
    
    expect(firstCheck, equals(secondCheck));
    expect(firstCheck, equals(initialState));
  }
});
```

### Integration Testing

Integration tests will verify:
- End-to-end permission request flow
- Method channel communication between Flutter and Android
- Sensor data flow from native to Flutter
- Lifecycle transitions (foreground/background)

### Manual Testing

Manual testing on physical Galaxy Watch 6 device will verify:
- Real sensor data accuracy
- Battery impact during extended tracking
- UI responsiveness during sensor operations
- Notification behavior

## Watch-to-Phone Data Flow

### Sequence Diagram

```
Watch App
  |
  |--[User starts tracking]-->
  |  MainActivity.kt (Watch)
  |
  |--[Connects to HealthTrackingService]-->
  |  HealthTrackingManager.kt
  |
  |--[onConnectionSuccess fires]-->
  |  HealthTrackingManager.kt
  |
  |--[Heart rate data received]-->
  |  HealthTrackingManager.kt
  |
  |--[Encode as JSON]-->
  |  WatchToPhoneSyncManager.kt
  |
  |--[Discover phone nodes via CapabilityClient]-->
  |  WatchToPhoneSyncManager.kt
  |
  |--[Send via MessageClient to "/heart_rate"]-->
  |  Wearable Data Layer API
  |
  |--[Phone receives message]-->
  |  PhoneDataListenerService.kt
  |
  |--[Filter by path "/heart_rate"]-->
  |  PhoneDataListenerService.kt
  |
  |--[Decode JSON]-->
  |  PhoneDataListenerService.kt
  |
  |--[Send to Flutter via EventChannel]-->
  |  MainActivity.kt (Phone)
  |
  |--[UI updated with BPM/IBI]-->
  |  Flutter UI
```

### Critical Implementation Details

1. **Wait for Connection Success**: The watch must wait for `onConnectionSuccess()` callback before checking capabilities or starting tracking. Accessing the service before connection completes will result in null binder errors.

2. **Use CapabilityClient for Node Discovery**: Never hardcode node IDs. Always use CapabilityClient to discover phone nodes with the `pulsify_phone_app` or `heart_rate_receiver` capability.

3. **Consistent Message Paths**: The message path must be exactly `/heart_rate` on both watch (send) and phone (receive). Any mismatch will cause messages to be ignored.

4. **Background Message Reception**: PhoneDataListenerService must be declared in AndroidManifest.xml with proper intent-filter to receive messages even when the app is closed.

5. **JSON Encoding**: Always encode data as JSON for extensibility and ease of parsing. Include all required fields: bpm, ibiValues, timestamp, status.

## Implementation Considerations

### Gradle Configuration

The `android/app/build.gradle.kts` must be updated to:
1. Add the local AAR file from `libs` directory
2. Include AndroidX Health Services dependency
3. Set minimum SDK to 30 for Wear OS 3.0+ support

```kotlin
dependencies {
    implementation(files("libs/samsung-health-sensor-api-1.4.1.aar"))
    implementation("androidx.health:health-services-client:1.0.0-beta03")
}

android {
    defaultConfig {
        minSdk = 30
    }
}
```

### AndroidManifest Configuration

**Watch App:**

Required permissions and queries:

```xml
<uses-permission android:name="android.permission.BODY_SENSORS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />

<queries>
    <package android:name="com.samsung.android.service.health.tracking" />
</queries>
```

**Phone App:**

PhoneDataListenerService declaration:

```xml
<service
    android:name=".PhoneDataListenerService"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <data
            android:host="*"
            android:pathPrefix="/heart_rate"
            android:scheme="wear" />
    </intent-filter>
</service>
```

**Critical:** The `pathPrefix` must be `/heart_rate` (not `/heart_rate_data`) to match the message path used by WatchToPhoneSyncManager.

**Phone App Capability Declaration (wear.xml):**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="android_wear_capabilities">
        <item>pulsify_phone_app</item>
        <item>heart_rate_receiver</item>
    </string-array>
</resources>
```

This capability declaration allows the watch to discover the phone app using CapabilityClient.

### Flutter Permission Plugin

Use the **permission_handler** plugin for runtime permission requests:

```yaml
dependencies:
  permission_handler: ^11.0.0
```

### Foreground Service

When tracking is active, run as a foreground service with notification:

```kotlin
class SensorTrackingService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }
}
```

### Resource Management

- Use Kotlin coroutines for async operations
- Implement proper lifecycle observers
- Release sensor listeners in onPause/onDestroy
- Cancel ongoing operations when disconnecting

### Battery Optimization

- Use sensor batching when possible
- Reduce sampling rate when app is in background
- Stop tracking when screen is off (unless explicitly required)
- Use WorkManager for periodic background sync

## Security Considerations

1. **Data Privacy**: Biometric data is sensitive - ensure proper encryption in transit and at rest
2. **Permission Scope**: Only request BODY_SENSORS when actually needed
3. **Data Retention**: Implement data retention policies and user data deletion
4. **Secure Storage**: Use Android Keystore for sensitive data
5. **API Key Protection**: Keep Samsung Health API credentials secure

## Performance Considerations

1. **Sensor Sampling Rate**: Balance between data accuracy and battery life
2. **Data Buffering**: Buffer sensor data before sending to Flutter to reduce channel overhead
3. **Memory Management**: Limit in-memory sensor data history
4. **Thread Management**: Use background threads for sensor operations
5. **Method Channel Overhead**: Batch data updates when possible

## Future Enhancements

1. Support for additional sensors (accelerometer, gyroscope, SpO2)
2. Historical data sync from Samsung Health
3. Workout session management
4. Sleep tracking integration
5. Multi-device support (phone + watch)
6. Offline data caching and sync
