# 🎯 Pulsify Smartwatch-to-Phone Data Flow Implementation Plan

## 📊 Current Status Analysis

### ✅ What's Already Implemented

**Flutter Side:**
- ✅ `WatchBridgeService` - Complete method channel wrapper
- ✅ Permission handling via `permission_handler` package
- ✅ Event channel for heart rate streaming
- ✅ Auto-sync functionality
- ✅ Retry logic with exponential backoff
- ✅ Error handling and logging

**Kotlin Side:**
- ✅ `HealthTrackingManager` - Samsung Health SDK integration
- ✅ `WatchToPhoneSyncManager` - Wearable Data Layer messaging
- ✅ `PhoneDataListenerService` - Background service for receiving data
- ✅ `MainActivity` - Method channel handlers
- ✅ Heart rate tracking with IBI data
- ✅ Connection management

**Android Manifest:**
- ✅ `BODY_SENSORS` permission declared
- ✅ Wear OS feature declaration
- ✅ `PhoneDataListenerService` registered
- ✅ Foreground service declarations

### ⚠️ What's Missing/Needs Enhancement

1. **Health Permissions for Android 15+ (BAKLAVA)**
   - Missing `android.permission.health.READ_HEART_RATE` handling
   - Need version-aware permission requests

2. **TrackedData Model Alignment**
   - Pure Kotlin uses `TrackedData(hr: Int, ibi: ArrayList<Int>)`
   - Current Flutter uses `HeartRateData(bpm: Int?, ibiValues: List<Int>)`
   - Need to align data structures

3. **Batch Data Sending**
   - Pure Kotlin sends last 40 HR values in batch
   - Current implementation sends single readings
   - Need to implement batch collection and transmission

4. **Phone-Side Flutter Integration**
   - Event channel registered but no Flutter UI consuming it
   - Need phone-side screen to display received data

5. **Connection State Management**
   - Need better connection state tracking
   - Missing connection status UI feedback

6. **Data Validation**
   - Need HR status validation (like pure Kotlin's `isHRValid()`)
   - Missing IBI status filtering

---

## 🚀 Implementation Plan

### **Phase 1: Fix Health Permissions (Android 15+ Support)** ⏱️ 30 mins

**Goal:** Support both `BODY_SENSORS` (Android 14-) and `health.READ_HEART_RATE` (Android 15+)

#### Tasks:

1. **Update AndroidManifest.xml**
   - Add `android.permission.health.READ_HEART_RATE`
   - Keep existing `BODY_SENSORS` for backward compatibility

2. **Update MainActivity.kt Permission Handling**
   - Add version check for Android 15+ (Build.VERSION_CODES.BAKLAVA)
   - Request appropriate permission based on Android version
   - Update `checkPermission()` to check correct permission

3. **Update WatchBridgeService (Flutter)**
   - Already uses `permission_handler` which handles this automatically
   - No changes needed on Flutter side

**Files to Modify:**
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/Pulsify/MainActivity.kt`

---

### **Phase 2: Align Data Models & Add Validation** ⏱️ 45 mins

**Goal:** Match the pure Kotlin data structure and validation logic

#### Tasks:

1. **Create TrackedData Model (Kotlin)**
   - Create `TrackedData.kt` data class matching pure Kotlin version
   - Add serialization support (kotlinx.serialization)

2. **Update HealthTrackingManager**
   - Add HR status validation (`isHRValid()`)
   - Add IBI status filtering
   - Store valid HR data in list (last 40 values)
   - Return `TrackedData` instead of `HeartRateData`

3. **Update Flutter Model**
   - Create `TrackedData` model in Flutter
   - Update `WatchBridgeService` to use new model
   - Keep backward compatibility with existing `HeartRateData`

**Files to Create:**
- `android/app/src/main/kotlin/com/example/Pulsify/TrackedData.kt`
- `lib/models/tracked_data.dart`

**Files to Modify:**
- `android/app/src/main/kotlin/com/example/Pulsify/HealthTrackingManager.kt`
- `lib/services/watch_bridge.dart`

---

### **Phase 3: Implement Batch Data Collection & Sending** ⏱️ 1 hour

**Goal:** Collect last 40 HR readings and send in batch to phone

#### Tasks:

1. **Update HealthTrackingManager**
   - Add `validHrData: ArrayList<TrackedData>` storage
   - Implement `trimDataList()` to keep only last 40 values
   - Add `getValidHrData()` method

2. **Add Batch Send Method Channel**
   - Add `sendBatchToPhone` method in MainActivity
   - Serialize ArrayList<TrackedData> to JSON
   - Use WatchToPhoneSyncManager to send

3. **Update WatchBridgeService (Flutter)**
   - Add `sendBatchToPhone()` method
   - Collect data over time
   - Trigger batch send on user action or timer

4. **Update WatchToPhoneSyncManager**
   - Already has `sendBatchToPhone()` - verify it works
   - Ensure proper JSON encoding

**Files to Modify:**
- `android/app/src/main/kotlin/com/example/Pulsify/HealthTrackingManager.kt`
- `android/app/src/main/kotlin/com/example/Pulsify/MainActivity.kt`
- `lib/services/watch_bridge.dart`

---

### **Phase 4: Phone-Side Data Reception & Display** ⏱️ 1 hour

**Goal:** Create phone UI to receive and display heart rate data from watch

#### Tasks:

1. **Create Phone Heart Rate Screen (Flutter)**
   - Create `lib/screens/phone/phone_heart_rate_screen.dart`
   - Listen to `com.pulsify.phone/heartrate` event channel
   - Display received HR and IBI data
   - Show connection status

2. **Update MainActivity for Phone**
   - Event channel already registered
   - Verify `PhoneDataListenerService.eventSink` connection

3. **Add Navigation**
   - Add route to phone heart rate screen
   - Add button in dashboard to access

4. **Handle Background Data**
   - When app is closed, service launches MainActivity
   - MainActivity should navigate to heart rate screen with data

**Files to Create:**
- `lib/screens/phone/phone_heart_rate_screen.dart`
- `lib/services/phone_data_receiver.dart`

**Files to Modify:**
- `lib/screens/dashboard.dart`
- `android/app/src/main/kotlin/com/example/Pulsify/MainActivity.kt`

---

### **Phase 5: Enhanced Connection Management** ⏱️ 45 mins

**Goal:** Better connection state tracking and UI feedback

#### Tasks:

1. **Add Connection State Stream**
   - Create connection state model
   - Add periodic connection checks
   - Emit connection state changes

2. **Update UI with Connection Status**
   - Show "Connected to Phone" / "Disconnected" indicator
   - Show node count
   - Show last sync time

3. **Add Manual Sync Button**
   - Button to trigger batch send
   - Show sync progress
   - Show success/failure feedback

**Files to Create:**
- `lib/models/connection_state.dart`

**Files to Modify:**
- `lib/services/watch_bridge.dart`
- `lib/screens/wear/wear_heart_rate_screen.dart`

---

### **Phase 6: Testing & Validation** ⏱️ 1 hour

**Goal:** Ensure end-to-end data flow works correctly

#### Tasks:

1. **Watch-Side Testing**
   - Test permission request flow
   - Test heart rate tracking start/stop
   - Test data streaming
   - Test batch send

2. **Phone-Side Testing**
   - Test data reception in background
   - Test data reception when app is open
   - Test UI updates

3. **Integration Testing**
   - Test watch → phone data flow
   - Test connection loss/recovery
   - Test multiple data points
   - Test batch transmission

4. **Edge Cases**
   - Test with no phone connected
   - Test with invalid HR data
   - Test permission denial
   - Test service disconnection

---

## 📋 Detailed File Changes

### **1. AndroidManifest.xml**

```xml
<!-- Add this permission for Android 15+ -->
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />

<!-- Keep existing BODY_SENSORS for Android 14- -->
<uses-permission android:name="android.permission.BODY_SENSORS" />
```

### **2. TrackedData.kt (NEW FILE)**

```kotlin
package com.example.pulsify

import kotlinx.serialization.Serializable

@Serializable
data class TrackedData(
    var hr: Int = 0,
    var ibi: ArrayList<Int> = ArrayList()
)
```

### **3. HealthTrackingManager.kt Updates**

```kotlin
// Add these properties
private val validHrData = ArrayList<TrackedData>()
private val maxDataPoints = 40

// Add validation method
private fun isHRValid(status: Int): Boolean = status == 1

// Update processDataPoint to store valid data
private fun processDataPoint(dataPoint: DataPoint) {
    val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE) as? Int
    val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS) as? Int
    
    if (isHRValid(hrStatus ?: -1) && hrValue != null) {
        val trackedData = TrackedData(hr = hrValue)
        
        // Add IBI values
        val ibiList = getValidIbiList(dataPoint)
        trackedData.ibi.addAll(ibiList)
        
        validHrData.add(trackedData)
        trimDataList()
        
        // Also send to Flutter
        onHeartRateData(convertToHeartRateData(trackedData))
    }
}

// Add trim method
private fun trimDataList() {
    while (validHrData.size > maxDataPoints) {
        validHrData.removeAt(0)
    }
}

// Add getter
fun getValidHrData(): ArrayList<TrackedData> = validHrData
```

### **4. MainActivity.kt Updates**

```kotlin
// Update permission handling
private fun requestPermission(result: MethodChannel.Result) {
    try {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            "android.permission.health.READ_HEART_RATE"
        } else {
            Manifest.permission.BODY_SENSORS
        }
        
        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
        } else {
            pendingPermissionResult = result
            ActivityCompat.requestPermissions(this, arrayOf(permission), PERMISSION_REQUEST_CODE)
        }
    } catch (e: Exception) {
        result.error("PERMISSION_ERROR", "Failed to request permission", e.message)
    }
}

// Add batch send method
private fun sendBatchToPhone(result: MethodChannel.Result) {
    val manager = healthTrackingManager
    if (manager == null) {
        result.error("MANAGER_ERROR", "Health tracking manager not initialized", null)
        return
    }
    
    val syncManager = watchToPhoneSyncManager
    if (syncManager == null) {
        result.error("SYNC_ERROR", "Sync manager not initialized", null)
        return
    }
    
    scope.launch {
        try {
            val data = manager.getValidHrData()
            val json = Json.encodeToString(data)
            
            syncManager.sendBatchToPhone(json) { success ->
                mainHandler.post {
                    result.success(success)
                }
            }
        } catch (e: Exception) {
            mainHandler.post {
                result.error("BATCH_ERROR", e.message, null)
            }
        }
    }
}
```

### **5. tracked_data.dart (NEW FILE)**

```dart
class TrackedData {
  final int hr;
  final List<int> ibi;
  
  TrackedData({
    required this.hr,
    required this.ibi,
  });
  
  factory TrackedData.fromJson(Map<String, dynamic> json) {
    return TrackedData(
      hr: json['hr'] ?? 0,
      ibi: List<int>.from(json['ibi'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hr': hr,
      'ibi': ibi,
    };
  }
}
```

### **6. phone_heart_rate_screen.dart (NEW FILE)**

```dart
class PhoneHeartRateScreen extends StatefulWidget {
  @override
  _PhoneHeartRateScreenState createState() => _PhoneHeartRateScreenState();
}

class _PhoneHeartRateScreenState extends State<PhoneHeartRateScreen> {
  static const eventChannel = EventChannel('com.pulsify.phone/heartrate');
  
  List<TrackedData> _receivedData = [];
  
  @override
  void initState() {
    super.initState();
    _listenToWatchData();
  }
  
  void _listenToWatchData() {
    eventChannel.receiveBroadcastStream().listen((data) {
      final jsonData = jsonDecode(data as String);
      
      if (jsonData is List) {
        // Batch data
        final batch = jsonData.map((item) => TrackedData.fromJson(item)).toList();
        setState(() => _receivedData.addAll(batch));
      } else {
        // Single data point
        final trackedData = TrackedData.fromJson(jsonData);
        setState(() => _receivedData.add(trackedData));
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Watch Data')),
      body: ListView.builder(
        itemCount: _receivedData.length,
        itemBuilder: (context, index) {
          final data = _receivedData[index];
          return ListTile(
            title: Text('HR: ${data.hr} bpm'),
            subtitle: Text('IBI: ${data.ibi.take(4).join(", ")}'),
          );
        },
      ),
    );
  }
}
```

---

## 🎯 Success Criteria

### Watch Side:
- ✅ Permissions requested correctly on Android 14 and 15+
- ✅ Heart rate tracking starts and streams data
- ✅ IBI values extracted and validated
- ✅ Last 40 readings stored in memory
- ✅ Batch send works and transmits to phone
- ✅ Connection status visible in UI

### Phone Side:
- ✅ Background service receives data
- ✅ Event channel delivers data to Flutter
- ✅ UI displays received heart rate data
- ✅ Batch data parsed and displayed
- ✅ App launches when data received in background

### Integration:
- ✅ End-to-end data flow: Watch → Wearable Data Layer → Phone
- ✅ Data structure matches between watch and phone
- ✅ No data loss during transmission
- ✅ Proper error handling at all layers

---

## 📊 Estimated Timeline

| Phase | Duration | Priority |
|-------|----------|----------|
| Phase 1: Health Permissions | 30 mins | 🔴 Critical |
| Phase 2: Data Models | 45 mins | 🔴 Critical |
| Phase 3: Batch Sending | 1 hour | 🟡 High |
| Phase 4: Phone UI | 1 hour | 🟡 High |
| Phase 5: Connection Management | 45 mins | 🟢 Medium |
| Phase 6: Testing | 1 hour | 🔴 Critical |
| **Total** | **5 hours** | |

---

## 🚦 Next Steps

1. **Start with Phase 1** - Fix health permissions (critical for Android 15+)
2. **Move to Phase 2** - Align data models (foundation for everything else)
3. **Implement Phase 3** - Batch sending (core feature)
4. **Build Phase 4** - Phone UI (user-facing feature)
5. **Add Phase 5** - Connection management (polish)
6. **Complete Phase 6** - Testing (validation)

---

## 📝 Notes

- **Existing code is 80% complete** - mostly need alignment and enhancements
- **No major architectural changes needed** - method channels already set up
- **Focus on data model alignment** - this is the key difference from pure Kotlin
- **Phone-side UI is the biggest gap** - need to create from scratch
- **Testing is critical** - watch-to-phone communication can be tricky

---

**Generated:** November 25, 2025  
**Status:** 📋 Ready for Implementation  
**Estimated Completion:** 5 hours of focused work
