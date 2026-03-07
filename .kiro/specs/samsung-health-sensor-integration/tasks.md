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

















  - Create android/app/src/main/kotlin/com/example/Pulsify/SamsungHealthManager.kt
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






  - Create EventChannel in MainActivity for "com.pulsify.watch/heartrate"
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

- [x] 17. Fix 5 critical production bugs blocking app functionality



  - Fix HealthTrackingManager connection lifecycle - implement proper ConnectionListener callback pattern
  - Fix race condition where capability check happens before service connection completes
  - Fix UI overflow in wear_heart_rate_screen.dart by adding SingleChildScrollView with proper constraints
  - Add wear.xml capability file for phone app to enable node discovery
  - Disable Impeller rendering to fix gralloc4 format errors
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 18. Fix watch-to-phone message path mismatch









  - Update WatchToPhoneSyncManager to use message path "/heart_rate" instead of "/heart_rate_data"
  - Update PhoneDataListenerService to use message path "/heart_rate" for consistency
  - Update AndroidManifest.xml intent-filter pathPrefix to "/heart_rate"
  - Verify MESSAGE_PATH and BATCH_PATH constants match across watch and phone
  - Test end-to-end data flow from watch sensor to phone UI
  - _Requirements: 8.1, 8.2, 9.1, 9.3_

- [ ]* 18.1 Write property test for watch data transmission
  - **Property 18: Watch data transmission to phone**
  - **Validates: Requirements 8.1**

- [ ]* 18.2 Write property test for phone receives data timely
  - **Property 19: Phone receives watch data timely**
  - **Validates: Requirements 8.2**

- [ ]* 18.3 Write property test for node discovery via capability
  - **Property 20: Node discovery via capability**
  - **Validates: Requirements 8.3**

- [ ]* 18.4 Write property test for graceful no phone handling
  - **Property 21: Graceful handling of no phone connection**
  - **Validates: Requirements 8.4**

- [ ]* 18.5 Write property test for phone app launch
  - **Property 22: Phone app launch on data reception**
  - **Validates: Requirements 8.5**

- [x] 19. Implement PhoneDataService in Flutter (phone side)









  - Create lib/services/phone_data_listener.dart for phone app
  - Set up EventChannel listener for "com.pulsify.phone/heartrate"
  - Implement JSON decoding with validation of required fields
  - Create Stream<HeartRateData> for phone UI to consume
  - Add error handling for malformed JSON
  - _Requirements: 8.2, 9.4_

- [ ]* 19.1 Write property test for consistent message path
  - **Property 23: Consistent message path usage**
  - **Validates: Requirements 9.1**

- [ ]* 19.2 Write property test for JSON encoding consistency
  - **Property 24: JSON encoding consistency**
  - **Validates: Requirements 9.2**

- [ ]* 19.3 Write property test for message path filtering
  - **Property 25: Message path filtering on phone**
  - **Validates: Requirements 9.3**

- [ ]* 19.4 Write property test for JSON decoding validation
  - **Property 26: JSON decoding validation**
  - **Validates: Requirements 9.4**

- [ ]* 19.5 Write property test for transmission error logging
  - **Property 27: Transmission error logging**
  - **Validates: Requirements 9.5**

- [x] 20. Update WatchBridgeService to support watch-to-phone sync









  - Add sendHeartRateToPhone() method that calls native sync manager
  - Add checkPhoneConnection() method
  - Add getConnectedNodesCount() method for debugging
  - Implement automatic sync when heart rate data is received
  - Add retry logic for failed transmissions
  - _Requirements: 8.1, 8.3, 8.4_

- [x] 21. Create phone UI for displaying watch data







  - Create screen to display heart rate data received from watch
  - Show connection status (watch connected/disconnected)
  - Display real-time BPM and IBI values
  - Add visual indicator for data freshness (timestamp)
  - Handle case when no data has been received yet
  - _Requirements: 8.2_

- [x] 22. Final checkpoint - Test watch-to-phone data flow





  - Ensure all tests pass, ask the user if questions arise.
  - Verify data flows from watch sensor → phone UI
  - Test with phone app closed (background reception)
  - Test with phone app open (real-time updates)
  - Verify node discovery works correctly
  - Check error handling when phone is disconnected

- [x] 23. Add Android 15+ health permission support






  - Update AndroidManifest.xml to declare android.permission.health.READ_HEART_RATE
  - Update MainActivity.kt requestPermission() to check Android version and request appropriate permission
  - Update checkPermission() to check the correct permission based on Android version
  - Test permission flow on Android 14 and Android 15+ devices
  - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [ ]* 23.1 Write property test for version-aware permission request
  - **Property 28: Android version-aware permission request**
  - **Validates: Requirements 10.1, 10.2**

- [x] 24. Create TrackedData model (Kotlin)






  - Create android/app/src/main/kotlin/com/example/Pulsify/TrackedData.kt
  - Add @Serializable annotation for JSON encoding
  - Define hr: Int and ibi: ArrayList<Int> fields
  - Add kotlinx.serialization dependency to build.gradle.kts if needed
  - _Requirements: 13.1_

- [x] 25. Create TrackedData model (Flutter)






  - Create lib/models/tracked_data.dart
  - Implement fromJson() factory constructor
  - Implement toJson() method
  - Add validation for required fields
  - _Requirements: 13.1, 13.2, 13.3_

- [ ]* 25.1 Write property test for TrackedData serialization round-trip
  - **Property 33: TrackedData serialization round-trip**
  - **Validates: Requirements 13.1, 13.2, 13.3**

- [x] 26. Add HR data validation to HealthTrackingManager








  - Implement isHRValid(status: Int) method that checks if status == 1
  - Update heart rate data processing to validate HR status before storing
  - Implement getValidIbiList() to filter IBI values by status
  - Only add TrackedData to collection when HR status is valid
  - _Requirements: 11.1, 11.2, 11.3_

- [ ]* 26.1 Write property test for HR status validation
  - **Property 29: Heart rate status validation**
  - **Validates: Requirements 11.1, 11.2**

- [ ]* 26.2 Write property test for IBI status filtering
  - **Property 30: IBI status filtering**
  - **Validates: Requirements 11.3**

- [x] 27. Implement batch data collection in HealthTrackingManager







  - Add validHrData: ArrayList<TrackedData> property
  - Add maxDataPoints = 40 constant
  - Implement trimDataList() to remove oldest data when size exceeds 40
  - Call trimDataList() after adding each new measurement
  - Implement getValidHrData() to return the collection
  - _Requirements: 12.1, 12.2, 12.3_

- [ ]* 27.1 Write property test for data collection size limit
  - **Property 31: Data collection size limit**
  - **Validates: Requirements 12.2**

- [x] 28. Add batch send method channel handler






  - Add "sendBatchToPhone" case to MainActivity handleMethodCall()
  - Call healthTrackingManager.getValidHrData() to retrieve batch
  - Serialize ArrayList<TrackedData> to JSON using kotlinx.serialization
  - Call watchToPhoneSyncManager.sendBatchToPhone() with JSON
  - Return success/failure result to Flutter
  - _Requirements: 12.3, 12.4_

- [ ]* 28.1 Write property test for batch data encoding
  - **Property 32: Batch data encoding**
  - **Validates: Requirements 12.4**

- [x] 29. Add batch send method to WatchBridgeService






  - Add sendBatchToPhone() method to WatchBridgeService
  - Call method channel with "sendBatchToPhone"
  - Add error handling for batch send failures
  - Return Future<bool> indicating success/failure
  - _Requirements: 12.3_

- [x] 30. Update PhoneDataListenerService to handle batch data






  - Update JSON parsing to detect if data is array or single object
  - If array, iterate and process each TrackedData item
  - If single object, process as before
  - Send each item to EventChannel sink
  - _Requirements: 12.5_

- [x] 31. Enhance phone UI for displaying watch data








  - Update phone heart rate screen to display TrackedData format
  - Show BPM value prominently with large font
  - Display IBI values in a readable list or chart
  - Add connection status indicator (connected/disconnected)
  - Show "No data received" message when data list is empty
  - Add timestamp for data freshness
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ]* 31.1 Write property test for phone UI displays data
  - **Property 34: Phone UI displays received data**
  - **Validates: Requirements 14.2, 14.3**

- [x] 32. Add connection state management






  - Create lib/models/connection_state.dart model
  - Add periodic connection checks in WatchBridgeService
  - Emit connection state changes through Stream
  - Update watch UI to show connection status
  - Add manual sync button to trigger batch send
  - _Requirements: 14.5_

- [x] 33. Final checkpoint - Test enhanced features







  - Test Android 15+ permission flow
  - Test HR data validation filters invalid data
  - Test batch collection maintains 40-item limit
  - Test batch send transmits all data correctly
  - Test phone UI displays TrackedData properly
  - Test connection state updates correctly
  - Ensure all tests pass, ask the user if questions arise.
