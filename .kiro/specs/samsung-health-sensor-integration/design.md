# Design Document: Samsung Health Sensor Integration

## Overview

This design document outlines the technical architecture for integrating Samsung Health Sensor API into the FlowFit Flutter application for Galaxy Watch 6 (Wear OS). The integration follows a layered architecture with clear separation between Flutter (Dart) and native Android (Kotlin) code, connected via Flutter's Method Channel mechanism.

The solution enables real-time biometric data collection from Samsung Galaxy Watch sensors, with proper permission handling, lifecycle management, and error handling throughout the stack.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Layer (Dart)            │
│  ┌───────────────────────────────────┐  │
│  │   UI Components & Screens         │  │
│  └───────────────┬───────────────────┘  │
│                  │                       │
│  ┌───────────────▼───────────────────┐  │
│  │   WatchBridgeService              │  │
│  │   - Permission Management         │  │
│  │   - Sensor Data Streams           │  │
│  └───────────────┬───────────────────┘  │
└──────────────────┼───────────────────────┘
                   │ Method Channel
┌──────────────────▼───────────────────────┐
│      Native Android Layer (Kotlin)       │
│  ┌───────────────────────────────────┐   │
│  │   MainActivity                    │   │
│  │   - Method Channel Handler        │   │
│  └───────────────┬───────────────────┘   │
│                  │                        │
│  ┌───────────────▼───────────────────┐   │
│  │   SamsungHealthManager           │   │
│  │   - Connection Management         │   │
│  │   - Sensor Listeners              │   │
│  │   - Lifecycle Handling            │   │
│  └───────────────┬───────────────────┘   │
└──────────────────┼────────────────────────┘
                   │
┌──────────────────▼────────────────────────┐
│   Samsung Health Sensor API               │
│   - Heart Rate Sensor                     │
│   - Accelerometer                         │
│   - Other Biometric Sensors               │
└───────────────────────────────────────────┘
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
  static const MethodChannel _channel = MethodChannel('com.flowfit.watch/data');
  
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

### 2. Native Android Layer Components

#### MainActivity (Kotlin)

Enhanced to handle Method Channel calls and route to SamsungHealthManager.

```kotlin
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.flowfit.watch/data"
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
            else -> result.notImplemented()
        }
    }
}
```

#### SamsungHealthManager (Kotlin)

Core manager for Samsung Health Sensor API integration.

```kotlin
class SamsungHealthManager(private val context: Context) {
    private var connectionListener: ConnectionListener? = null
    private var heartRateListener: HeartRateListener? = null
    private var isConnected: Boolean = false
    
    // Connection management
    fun connect(callback: (Boolean, String?) -> Unit)
    fun disconnect()
    fun isConnected(): Boolean
    
    // Heart rate tracking
    fun startHeartRateTracking(callback: (Int, Long) -> Unit)
    fun stopHeartRateTracking()
    fun getLastHeartRate(): Pair<Int, Long>?
    
    // Lifecycle
    fun onResume()
    fun onPause()
    fun onDestroy()
}
```

### 3. Method Channel Protocol

#### Method Calls (Flutter → Android)

| Method | Arguments | Return Type | Description |
|--------|-----------|-------------|-------------|
| `requestPermission` | None | `bool` | Request BODY_SENSORS permission |
| `checkPermission` | None | `String` | Check permission status |
| `connectWatch` | None | `bool` | Connect to Samsung Health |
| `disconnectWatch` | None | `void` | Disconnect from Samsung Health |
| `startHeartRate` | None | `bool` | Start heart rate tracking |
| `stopHeartRate` | None | `void` | Stop heart rate tracking |
| `getCurrentHeartRate` | None | `Map` | Get latest heart rate data |

#### Event Channels (Android → Flutter)

| Channel | Data Type | Description |
|---------|-----------|-------------|
| `com.flowfit.watch/heartrate` | `Map<String, dynamic>` | Stream of heart rate updates |

## Data Models

### HeartRateData

```dart
{
  "bpm": int,           // Beats per minute
  "timestamp": int,     // Unix timestamp in milliseconds
  "status": String,     // "active", "inactive", "error", "unavailable"
  "ibi": int?          // Inter-beat interval (optional)
}
```

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

Required permissions and queries:

```xml
<uses-permission android:name="android.permission.BODY_SENSORS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />

<queries>
    <package android:name="com.samsung.android.service.health.tracking" />
</queries>
```

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
