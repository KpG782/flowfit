# WORKING_KOTLIN_HR_FLOW_ANALYSIS.md

---

# Table of Contents
- [Quick Reference](#quick-reference)
- [Key Differences from Typical Implementations](#key-differences-from-typical-implementations)
- [Complete Architecture Overview](#complete-architecture-overview)
- [Step-by-Step Code Flow Analysis](#step-by-step-code-flow-analysis)
  - [Watch Side](#watch-side)
  - [Phone Side](#phone-side)
- [Critical Configuration Files](#critical-configuration-files)
- [Data Structure Documentation](#data-structure-documentation)
- [Sequence Diagram](#sequence-diagram)
- [Common Pitfalls & Solutions](#common-pitfalls--solutions)
- [Permission Flow](#permission-flow)
- [Thread Safety & Async Operations](#thread-safety--async-operations)
- [Error Handling Patterns](#error-handling-patterns)
- [Comparison Checklist](#comparison-checklist)

---

## Quick Reference
- **Watch-to-Phone Data Path:** Watch (Samsung Health SDK) → HealthTrackingManager → MessageSender → Wearable Data Layer → Phone (DataListenerService) → MainActivity
- **Message Path:** `/heart_rate`
- **Data Format:** JSON `{ bpm, ibiValues, timestamp, status }`
- **Key Capabilities:** ConnectionListener, CapabilityClient, WearableListenerService

---

## Key Differences from Typical Implementations
> **Note:** This sample uses Samsung Health SDK and Wearable Data Layer APIs for robust, background-capable heart rate transfer. Key differences:
- Waits for `onConnectionSuccess()` before capability checks (avoids binder null errors)
- Uses CapabilityClient for node discovery (not hardcoded node IDs)
- DataListenerService declared in manifest for background message reception
- JSON encoding for extensible data transfer
- Handles permissions and errors explicitly

---

## Complete Architecture Overview
```
┌─────────────────────────────────────────────────────┐
│                 GALAXY WATCH (Wear OS)              │
│  ┌──────────────────────────────────────────────┐  │
│  │ 1. MainActivity.kt (Watch)                   │  │
│  │    - Initializes Samsung Health SDK          │  │
│  │    - Creates HealthTrackingManager           │  │
│  │    - Starts heart rate tracking              │  │
│  └──────────────┬───────────────────────────────┘  │
│                 │                                    │
│  ┌──────────────▼───────────────────────────────┐  │
│  │ 2. HealthTrackingManager.kt (Watch)          │  │
│  │    - Connects to HealthTrackingService       │  │
│  │    - Implements ConnectionListener           │  │
│  │    - Tracks heart rate data                  │  │
│  │    - Extracts BPM & IBI values               │  │
│  └──────────────┬───────────────────────────────┘  │
│                 │                                    │
│  ┌──────────────▼───────────────────────────────┐  │
│  │ 3. MessageSender.kt (Watch)                  │  │
│  │    - Uses MessageClient API                  │  │
│  │    - Finds phone nodes via CapabilityClient  │  │
│  │    - Encodes data as JSON                    │  │
│  │    - Sends to path: "/heart_rate"            │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────┘
                      │
                      │ Wearable Data Layer API
                      │ (MessageClient)
                      │
┌─────────────────────▼───────────────────────────────┐
│              ANDROID PHONE (Companion)              │
│  ┌──────────────────────────────────────────────┐  │
│  │ 4. DataListenerService.kt (Phone)            │  │
│  │    - Extends WearableListenerService         │  │
│  │    - Declared in AndroidManifest.xml         │  │
│  │    - Listens for MESSAGE_RECEIVED intent     │  │
│  │    - Filters path: "/heart_rate"             │  │
│  └──────────────┬───────────────────────────────┘  │
│                 │                                    │
│  ┌──────────────▼───────────────────────────────┐  │
│  │ 5. MainActivity.kt (Phone)                   │  │
│  │    - Receives Intent with heart rate data    │  │
│  │    - Decodes JSON to HeartRateData object    │  │
│  │    - Updates UI with BPM & IBI values        │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Step-by-Step Code Flow Analysis

### Watch Side

#### File: `MainActivity.kt` (Watch)
**Purpose:**
Initializes Samsung Health SDK, requests permissions, and starts heart rate tracking via HealthTrackingManager.

**Key Components:**
- `onCreate()`: Initializes SDK, sets up UI, requests BODY_SENSORS permission
- Button handlers: Start/stop tracking
- Permissions: Requests BODY_SENSORS at runtime

**Code Flow:**
1. User taps "Start Tracking" button
2. Calls `healthTrackingManager.connect()`
3. On connection, starts heart rate tracking
4. Receives data, passes to MessageSender

**Critical Code Sections:**
```kotlin
// ...existing code...
healthTrackingManager.connect()
// ...existing code...
```

---

#### File: `HealthTrackingManager.kt` (Watch)
**Purpose:**
Manages connection to Samsung HealthTrackingService, tracks heart rate, extracts BPM/IBI, and notifies listeners.

**Connection Lifecycle:**
1. `connectService()` called
2. `ConnectionListener.onConnectionSuccess()` fires
3. Check capabilities: `hasHeartRateCapability()`
4. Create tracker: `getHealthTracker(HealthTrackerType.HEART_RATE_CONTINUOUS)`
5. Set listener: `setEventListener(trackerEventListener)`

**Data Extraction:**
```kotlin
val bpm = dataPoint.getValue("bpm")
val ibiValues = dataPoint.getValue("ibiValues")
```

**Working Code Patterns:**
- Wait for `onConnectionSuccess()` before accessing capabilities
- Use event listener for real-time data

---

#### File: `MessageSender.kt` (Watch)
**Purpose:**
Discovers phone node via CapabilityClient, encodes heart rate data as JSON, sends via MessageClient to `/heart_rate` path.

**Node Discovery:**
- Uses CapabilityClient to find nodes with `heart_rate_receiver` capability

**Message Format:**
```json
{
  "bpm": 72,
  "ibiValues": [850, 845, 855, 848],
  "timestamp": 1732507200000,
  "status": "valid"
}
```

**Send Mechanism:**
```kotlin
messageClient.sendMessage(nodeId, "/heart_rate", jsonData.toByteArray())
```

---

### Phone Side

#### File: `AndroidManifest.xml` (Phone)
**DataListenerService Declaration:**
```xml
<service
    android:name=".DataListenerService"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <data android:scheme="" android:host="" android:path="/heart_rate" />
    </intent-filter>
</service>
```

**Intent Filters:**
- Listens for `MESSAGE_RECEIVED` on `/heart_rate` path

**Why This Works:**
- Ensures service receives messages even when app is closed

---

#### File: `DataListenerService.kt` (Phone)
**Purpose:**
Extends WearableListenerService, receives messages from watch, forwards data to MainActivity.

**Message Reception:**
```kotlin
override fun onMessageReceived(event: MessageEvent) {
    if (event.path == "/heart_rate") {
        val data = String(event.data)
        // Forward to MainActivity
    }
}
```

**Data Forwarding:**
- Uses Intent to launch MainActivity with heart rate data

---

#### File: `MainActivity.kt` (Phone)
**Purpose:**
Handles UI, receives heart rate data via Intent, displays BPM/IBI.

**Intent Handling:**
- Receives Intent from DataListenerService
- Decodes JSON to HeartRateData

**UI Updates:**
- Updates TextViews with BPM/IBI

---

## Critical Configuration Files

### `build.gradle.kts` (Watch)
**Samsung Health SDK Integration:**
- AAR file location: `wear/libs/samsung-health-sensor-api-1.4.1.aar`
- Version: `1.4.1`
- Dependencies: `implementation files('libs/samsung-health-sensor-api-1.4.1.aar')`

**Play Services Wearable:**
- Version: e.g. `18.0.0`
- Why needed: For MessageClient, CapabilityClient APIs

---

### `build.gradle.kts` (Phone)
**Wearable Data Layer:**
- `play-services-wearable:18.0.0`
- Why needed: For WearableListenerService, message reception

---

### `AndroidManifest.xml` (Watch)
**Permissions:**
- `BODY_SENSORS`: Required for heart rate access
- Others: `INTERNET`, `FOREGROUND_SERVICE`, etc.

**Service Declarations:**
- Declare any background services if used

---

### `wear.xml` (Phone)
**Capability Declaration:**
```xml
<capability name="heart_rate_receiver" />
```

**Why This Matters:**
- Advertises phone's ability to receive heart rate data for node discovery

---

## Data Structure Documentation

**Heart Rate Data Object:**
```kotlin
data class HeartRateData(
    val bpm: Int,
    val ibiValues: List<Int>,
    val timestamp: Long,
    val status: String
)
```

**JSON Format Sent Over Wire:**
```json
{
  "bpm": 72,
  "ibiValues": [850, 845, 855, 848],
  "timestamp": 1732507200000,
  "status": "valid"
}
```

---

## Sequence Diagram
```
Watch App
  |
  |--[User taps Start]-->
  |  MainActivity.kt
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
  |--[Send JSON via MessageClient]-->
  |  MessageSender.kt
  |
  |--[Wearable Data Layer]-->
  |  (MessageClient)
  |
  |--[Phone receives message]-->
  |  DataListenerService.kt
  |
  |--[Intent to MainActivity]-->
  |  MainActivity.kt
  |
  |--[UI updated with BPM/IBI]-->
  |  MainActivity.kt
```

---

## Common Pitfalls & Solutions
| ❌ Common Mistake | ✅ Working Solution | Why It Matters |
|-------------------|---------------------|----------------|
| Checking capabilities before connection | Wait for onConnectionSuccess() callback | Client binder is null before connection |
| Hardcoded node IDs | Use CapabilityClient for discovery | Ensures dynamic, robust node selection |
| Not declaring service in manifest | Declare DataListenerService with intent-filter | Enables background message reception |
| Not handling permissions | Request BODY_SENSORS at runtime | Prevents security exceptions |
| Not encoding data as JSON | Use JSON for extensibility | Future-proof, easy parsing |

---

## Permission Flow
```
1. BODY_SENSORS permission
   - Requested at: App launch (MainActivity.kt)
   - Checked at: Before starting tracking
   - Handled if denied: Show rationale, disable tracking

2. INTERNET, FOREGROUND_SERVICE
   - Requested in manifest
   - Used for network/service operations
```

---

## Thread Safety & Async Operations
- UI thread: MainActivity UI updates
- Background thread: HealthTrackingManager event listener, MessageClient send
- Callbacks: ConnectionListener, TrackerEventListener
- Data synchronized via event listeners and Intents

---

## Error Handling Patterns
- Connection errors: Handled in `onConnectionFailed()`
- Permission errors: Checked before starting tracking, handled with user prompts
- Message send failures: Caught and logged, retry logic possible
- Data parsing errors: Try/catch around JSON decode, fallback to default values

---

## Comparison Checklist

### Watch Side Comparison
#### HealthTracking Connection
- [ ] Uses ConnectionListener interface
- [ ] Waits for onConnectionSuccess() before checking capabilities
- [ ] Implements onConnectionFailed() with error handling
- [ ] Uses proper service binding lifecycle
- [ ] [Add more items...]

#### Message Sending
- [ ] Uses CapabilityClient to find phone nodes
- [ ] Checks for "heart_rate_receiver" capability
- [ ] Encodes data as JSON before sending
- [ ] Uses correct message path ("/heart_rate")
- [ ] [Add more items...]

### Phone Side Comparison
#### DataListenerService
- [ ] Extends WearableListenerService
- [ ] Properly declared in AndroidManifest.xml
- [ ] Has correct intent-filter for MESSAGE_RECEIVED
- [ ] Filters messages by path
- [ ] [Add more items...]

#### Data Reception
- [ ] Decodes JSON correctly
- [ ] Launches activity when app is closed
- [ ] Displays data in UI
- [ ] [Add more items...]

---

> **Use this document to compare your Pulsify Flutter app and identify missing or different components.**

---

**End of Document**
