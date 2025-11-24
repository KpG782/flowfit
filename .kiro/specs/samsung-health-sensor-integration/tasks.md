# Implementation Plan

- [x] 1. Configure Android build system and manifest




















  - Update `android/app/build.gradle.kts` to include the samsung-health-sensor-api.aar from libs directory
  - Add androidx.health:health-services-client dependency
  - Set minSdk to 30 for Wear OS 3.0+ support
  - Update `android/app/src/main/AndroidManifest.xml` to declare BODY_SENSORS permission
  - Add FOREGROUND_SERVICE and FOREGROUND_SERVICE_HEALTH permissions to manifest
  - Add queries tag for com.samsung.android.service.health.tracking package
  - _Requirements: 1.1, 1.2, 1.4, 2.1, 2.2, 2.3_
-

- [x] 2. Set up Flutter dependencies and data models







  - Add permission_handler package to pubspec.yaml
  - Create HeartRateData model class with bpm, timestamp, and status fields
  - Create SensorStatus enum (active, inactive, error, unavailable)
  - Create PermissionStatus enum (granted, denied, notDetermined)
  - Create SensorError class with error codes and descriptive messages
  - Create SensorErrorCode enum for different error types
  - _Requirements: 3.1, 6.1_

- [x] 2.1 Write unit tests for data models






  - Test HeartRateData serialization to/from JSON
  - Test SensorError creation and formatting
  - _Requirements: 6.1_
- [x] 3. Implement WatchBridgeService in Flutter

















- [ ] 3. Implement WatchBridgeService in Flutter

  - Create lib/services/watch_bridge.dart with MethodChannel setup
  - Implement requestBodySensorPermission() method using permission_handler
  - Implement checkBodySensorPermission() method
  - Implement connectToWatch() method that calls native code
  - Implement disconnectFromWatch() method
  - Implement isWatchConnected() method
  - Add error handling for all method channel calls
  - _Requirements: 3.1, 3.5, 4.1, 4.2, 4.3, 5.1, 5.2_

- [ ]* 3.1 Write property test for permission check idempotence
  - **Property 2: Permission check is idempotent**
  - **Validates: Requirements 3.5**

- [ ]* 3.2 Write property test for method channel routing
  - **Property 4: Method channel routes to correct handler**
  - **Validates: Requirements 4.1**

- [ ]* 3.3 Write property test for method channel round-trip
  - **Property 5: Method channel round-trip**
  - **Validates: Requirements 4.2**

- [ ]* 3.4 Write property test for error propagation
  - **Property 6: Error propagation**
  - **Validates: Requirements 4.3**
-

- [x] 4. Implement heart rate streaming in WatchBridgeService










  - Set up EventChannel for heart rate data stream
  - Implement startHeartRateTracking() method
  - Implement stopHeartRateTracking() method
  - Implement getCurrentHeartRate() method
  - Create Stream<HeartRateData> for real-time heart rate updates
  - Add stream error handling and cancellation
  - _Requirements: 6.1, 6.3_

- [ ]* 4.1 Write property test for tracking lifecycle consistency
  - **Property 12: Tracking lifecycle consistency**
  - **Validates: Requirements 6.1, 6.3**

- [x] 5. Create SamsungHealthManager in Kotlin

















  - Create android/app/src/main/kotlin/com/example/flowfit/SamsungHealthManager.kt
  - Implement connection management (connect, disconnect, isConnected)
  - Add ConnectionListener for Samsung Health service callbacks
  - Implement service availability check
  - Add connection state tracking (connected, disconnected, error)
  - Implement error handling with descriptive error messages
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ]* 5.1 Write property test for service availability check
  - **Property 7: Service availability check on startup**
  - **Validates: Requirements 5.1**

- [ ]* 5.2 Write property test for connection when services available
  - **Property 8: Connection establishes when services available**
  - **Validates: Requirements 5.2**

- [ ]* 5.3 Write property test for sensor support verification
  - **Property 9: Sensor support verification after connection**
  - **Validates: Requirements 5.3**

- [ ]* 5.4 Write property test for connection failure error info
  - **Property 10: Connection failure provides error information**
  - **Validates: Requirements 5.4**

- [ ]* 5.5 Write property test for disconnect on close
  - **Property 11: Disconnect on application close**
  - **Validates: Requirements 5.5**

- [x] 6. Implement heart rate tracking in SamsungHealthManager





  - Add HeartRateListener implementation for Samsung Health SDK
  - Implement startHeartRateTracking() with sensor initialization
  - Implement stopHeartRateTracking() with proper cleanup
  - Implement getLastHeartRate() to retrieve cached data
  - Add callback mechanism to send data to MainActivity
  - Handle sensor unavailable and error states
  - _Requirements: 6.1, 6.3, 6.4_

- [ ]* 6.1 Write property test for sensor unavailability handling
  - **Property 13: Sensor unavailability handling**
  - **Validates: Requirements 6.4**

- [x] 7. Update MainActivity method channel handlers




  - Implement requestPermission handler that checks Android permission
  - Implement checkPermission handler that returns current permission state
  - Implement connectWatch handler that calls SamsungHealthManager.connect()
  - Implement disconnectWatch handler
  - Implement startHeartRate handler
  - Implement stopHeartRate handler
  - Implement getCurrentHeartRate handler
  - Add proper error handling and result callbacks for all handlers
  - _Requirements: 3.1, 3.5, 4.1, 4.2, 4.3, 5.2, 6.1_

- [x] 8. Implement EventChannel for heart rate streaming






  - Create EventChannel in MainActivity for "com.flowfit.watch/heartrate"
  - Implement StreamHandler for heart rate data events
  - Connect SamsungHealthManager callbacks to EventChannel sink
  - Handle stream cancellation and cleanup
  - Add error event handling
  - _Requirements: 6.1, 6.2_
-

- [x] 9. Implement lifecycle management in SamsungHealthManager



  - Add onResume() method to resume tracking if previously active
  - Add onPause() method to pause non-critical tracking
  - Add onDestroy() method for complete cleanup
  - Track previous tracking state for resume functionality
  - Implement state persistence for background/foreground transitions
  - _Requirements: 7.1, 7.2_

- [ ]* 9.1 Write property test for background pause behavior
  - **Property 14: Background pause behavior**
  - **Validates: Requirements 7.1**

- [ ]* 9.2 Write property test for foreground resume behavior
  - **Property 15: Foreground resume behavior**
  - **Validates: Requirements 7.2**

- [x] 10. Implement foreground service for active tracking





  - Create SensorTrackingService extending Service
  - Implement notification creation for foreground service
  - Start foreground service when heart rate tracking begins
  - Stop foreground service when all tracking stops
  - Add notification channel setup for Android O+
  - Handle service lifecycle (onStartCommand, onDestroy)
  - _Requirements: 7.3, 7.4_

- [ ]* 10.1 Write property test for foreground service during tracking
  - **Property 16: Foreground service during active tracking**
  - **Validates: Requirements 7.3**

- [ ]* 10.2 Write property test for service cleanup on stop
  - **Property 17: Service cleanup on tracking stop**
  - **Validates: Requirements 7.4**
-

- [x] 11. Connect lifecycle events in MainActivity



  - Override onResume() to call SamsungHealthManager.onResume()
  - Override onPause() to call SamsungHealthManager.onPause()
  - Override onDestroy() to call SamsungHealthManager.onDestroy()
  - Ensure proper cleanup of method channel and event channel
  - _Requirements: 7.1, 7.2, 5.5_

- [x] 12. Implement permission state UI updates





  - Create permission state listener in WatchBridgeService
  - Emit permission state changes through a Stream
  - Update UI components to listen to permission state stream
  - Display appropriate messages for denied permissions
  - Add "Open Settings" button for permission management
  - _Requirements: 3.2, 3.3, 3.4_

- [ ]* 12.1 Write property test for permission state determines availability
  - **Property 1: Permission state determines sensor availability**
  - **Validates: Requirements 3.2, 3.3**

- [ ]* 12.2 Write property test for UI reflects permission state
  - **Property 3: UI reflects permission state**
  - **Validates: Requirements 3.4**

- [x] 13. Add comprehensive error handling




  - Implement try-catch blocks in all WatchBridgeService methods
  - Map native exceptions to SensorError objects
  - Add retry logic for connection failures with exponential backoff
  - Implement timeout handling for sensor operations
  - Add logging for debugging (use Flutter's logger package)
  - _Requirements: 4.3, 5.4, 6.4_

- [ ] 14. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 15. Create integration tests
  - Test end-to-end permission request flow
  - Test method channel communication with mocked native responses
  - Test sensor data flow from EventChannel to Flutter
  - Test lifecycle transitions (background/foreground)
  - _Requirements: 3.1, 4.1, 6.1, 7.1, 7.2_

- [ ]* 16. Add documentation and code comments
  - Document WatchBridgeService public API
  - Add KDoc comments to SamsungHealthManager
  - Document method channel protocol
  - Add README with setup instructions
  - Document permission request flow
  - _Requirements: All_
