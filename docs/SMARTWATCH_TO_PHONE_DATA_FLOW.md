# SmartWatch to Phone Live Data Flow - Kotlin Implementation

## 🎯 Overview
This document details the comprehensive flow of real-time heart rate and IBI (Inter-Beat Interval) data transmission from a Samsung smartwatch (Wear OS) to an Android phone using Kotlin, highlighting the **critical importance of health permissions**.

---

## 🔐 **CRITICAL: Health Permissions - The Foundation**

### ⚠️ **Why Health Permissions Are Essential**

**Without proper health permissions, NO health data can be accessed or transmitted!**

The Wear OS app REQUIRES explicit health sensor permissions before any heart rate monitoring can begin. This is enforced at multiple levels:

### **Wear Module (Smartwatch) - Permission Implementation**

**Location:** `wear/src/main/java/com/Pulsify/presentation/ui/Permission.kt`

```kotlin
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun Permission(
    onPermissionGranted: @Composable () -> Unit,
) {
    val permissionList: MutableList<String> = ArrayList()
    
    // API Level specific permission handling
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
        permissionList.add(HealthPermissions.READ_HEART_RATE)
    } else {
        permissionList.add(android.Manifest.permission.BODY_SENSORS)
    }
    
    val bodySensorPermissionState = rememberMultiplePermissionsState(permissionList)
    val lifecycleOwner = LocalLifecycleOwner.current
    
    DisposableEffect(key1 = lifecycleOwner, effect = {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> {
                    Log.i(TAG, "Lifecycle.Event.ON_START")
                    bodySensorPermissionState.launchMultiplePermissionRequest()
                }
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    })

    // Only show main UI if permissions are granted
    if (bodySensorPermissionState.allPermissionsGranted) {
        onPermissionGranted()
    } else {
        // Show permission rationale UI
        Row(
            Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            val textToShow = if (bodySensorPermissionState.shouldShowRationale) {
                stringResource(R.string.permission_should_show_rationale)
            } else {
                stringResource(R.string.permission_permanently_denied)
            }
            Text(
                modifier = Modifier.width(180.dp),
                textAlign = TextAlign.Center,
                fontSize = 13.sp,
                text = textToShow
            )
        }
    }
}
```

### **Android Manifest Declarations**

**Location:** `wear/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.BODY_SENSORS" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
```

**Key Points:**
- `BODY_SENSORS`: Required for Android SDK < 35 (pre-BAKLAVA)
- `health.READ_HEART_RATE`: Required for Android SDK >= 35 (BAKLAVA+)
- `WAKE_LOCK`: Keeps screen on during tracking
- **Both permissions declared to support all Android versions**

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     WEAR MODULE (Smartwatch)                │
├─────────────────────────────────────────────────────────────┤
│  1. Permission Layer (Permission.kt)                        │
│     ↓                                                        │
│  2. UI Layer (MainActivity.kt, MainScreen.kt)               │
│     ↓                                                        │
│  3. ViewModel (MainViewModel.kt)                            │
│     ↓                                                        │
│  4. Domain Layer (Use Cases)                                │
│     ├── TrackHeartRateUseCase                               │
│     ├── SendMessageUseCase                                  │
│     └── GetCapableNodes                                     │
│     ↓                                                        │
│  5. Data Layer (Repositories)                               │
│     ├── TrackingRepository (Samsung Health SDK)            │
│     ├── MessageRepository (Wearable Data Layer)            │
│     └── CapabilityRepository (Device Discovery)            │
│                                                             │
│              ▼▼▼ NETWORK TRANSMISSION ▼▼▼                  │
└─────────────────────────────────────────────────────────────┘
                            ║
                  Google Wearable Data Layer
                  (Bluetooth/WiFi Network)
                            ║
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE MODULE (Phone)                    │
├─────────────────────────────────────────────────────────────┤
│  1. DataListenerService.kt (Background Service)             │
│     ↓                                                        │
│  2. Intent Launch → MainActivity.kt                         │
│     ↓                                                        │
│  3. HelpFunctions.decodeMessage()                           │
│     ↓                                                        │
│  4. MainScreen.kt (Display UI)                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Detailed Data Flow

### **PHASE 1: Permission Request & Setup (WEAR)**

**Location:** `wear/src/main/java/com/Pulsify/presentation/MainActivity.kt`

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    private val viewModel by viewModels<MainViewModel>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            // 1. Permission wrapper - FIRST GATE
            Permission {
                // Only accessible after permissions granted
                MainScreen(
                    connectionState.connected,
                    connectionState.message,
                    trackingState.trackingRunning,
                    trackingState.trackingError,
                    trackingState.message,
                    trackingState.valueHR,
                    trackingState.valueIBI,
                    { viewModel.startTracking() },
                    { viewModel.stopTracking() },
                    { viewModel.sendMessage() }
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (!viewModel.connectionState.value.connected) {
            viewModel.setUpTracking()
        }
    }
}
```

**Permission Flow:**
1. **App Launch** → Permission check triggered
2. **ON_START Lifecycle Event** → Request permissions
3. **User Grants/Denies** → UI updates accordingly
4. **Permission Granted** → MainScreen becomes accessible
5. **Permission Denied** → Show rationale/permanent denial message

---

### **PHASE 2: Samsung Health Service Connection (WEAR)**

**Location:** `wear/src/main/java/com/Pulsify/presentation/MainViewModel.kt`

```kotlin
fun setUpTracking() {
    viewModelScope.launch {
        makeConnectionToHealthTrackingServiceUseCase().collect { connectionMessage ->
            when (connectionMessage) {
                is ConnectionMessage.ConnectionSuccessMessage -> {
                    _connectionState.value = ConnectionState(
                        connected = true,
                        message = "Connected to Health Tracking Service",
                        connectionException = null
                    )
                }
                is ConnectionMessage.ConnectionFailedMessage -> {
                    _connectionState.value = ConnectionState(
                        connected = false,
                        message = "Connection to Health Tracking Service failed",
                        connectionException = connectionMessage.exception
                    )
                }
                is ConnectionMessage.ConnectionEndedMessage -> {
                    _connectionState.value = ConnectionState(
                        connected = false,
                        message = "Connection ended. Try again later",
                        connectionException = null
                    )
                }
            }
        }
    }
}
```

**States:**
- ✅ **Connected**: Health Tracking Service ready
- ❌ **Failed**: Samsung Health SDK issue
- ⚠️ **Ended**: Connection lost

---

### **PHASE 3: Heart Rate Tracking Initiation (WEAR)**

**Location:** `wear/src/main/java/com/Pulsify/presentation/MainViewModel.kt`

```kotlin
fun startTracking() {
    trackingJob?.cancel()
    
    if (areTrackingCapabilitiesAvailableUseCase()) {
        trackingJob = viewModelScope.launch {
            trackHeartRateUseCase().collect { trackerMessage ->
                when (trackerMessage) {
                    is TrackerMessage.DataMessage -> {
                        processExerciseUpdate(trackerMessage.trackedData)
                    }
                    is TrackerMessage.FlushCompletedMessage -> {
                        // Tracking stopped cleanly
                        _trackingState.value = TrackingState(...)
                    }
                    is TrackerMessage.TrackerErrorMessage -> {
                        // Handle sensor errors
                        _trackingState.value = TrackingState(...)
                    }
                    is TrackerMessage.TrackerWarningMessage -> {
                        // Handle warnings (watch not worn, movement, etc.)
                        _trackingState.value = TrackingState(...)
                    }
                }
            }
        }
    } else {
        // Capabilities not available
        _trackingState.value = TrackingState(
            trackingError = true,
            message = "HR tracking capabilities not available"
        )
    }
}
```

---

### **PHASE 4: Real-Time Data Collection (WEAR)**

**Location:** `wear/src/main/java/com/Pulsify/data/TrackingRepositoryImpl.kt`

```kotlin
override suspend fun track(): Flow<TrackerMessage> = callbackFlow {
    val updateListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(dataPoints: MutableList<DataPoint>) {
            for (dataPoint in dataPoints) {
                var trackedData: TrackedData? = null
                
                // Extract Heart Rate
                val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE)
                val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS)
                
                if (isHRValid(hrStatus)) {
                    trackedData = TrackedData()
                    trackedData.hr = hrValue
                    Log.i(TAG, "valid HR: $hrValue")
                } else {
                    // Send warning message if HR invalid
                    coroutineScope.runCatching {
                        trySendBlocking(TrackerMessage.TrackerWarningMessage(getError(hrStatus.toString())))
                    }
                }
                
                // Extract IBI (Inter-Beat Interval)
                val validIbiList = getValidIbiList(dataPoint)
                if (validIbiList.isNotEmpty()) {
                    if (trackedData == null) trackedData = TrackedData()
                    trackedData.ibi.addAll(validIbiList)
                }
                
                // Emit tracked data
                if ((isHRValid(hrStatus) || validIbiList.isNotEmpty()) && trackedData != null) {
                    coroutineScope.runCatching {
                        trySendBlocking(TrackerMessage.DataMessage(trackedData))
                    }
                }
                
                if (trackedData != null) {
                    validHrData.add(trackedData)
                }
            }
            trimDataList() // Keep only last 40 values
        }

        override fun onFlushCompleted() {
            coroutineScope.runCatching {
                trySendBlocking(TrackerMessage.FlushCompletedMessage)
            }
        }

        override fun onError(trackerError: HealthTracker.TrackerError?) {
            coroutineScope.runCatching {
                trySendBlocking(TrackerMessage.TrackerErrorMessage(getError(trackerError.toString())))
            }
        }
    }

    heartRateTracker = healthTrackingService!!.getHealthTracker(HealthTrackerType.HEART_RATE_CONTINUOUS)
    setListener(updateListener)

    awaitClose {
        stopTracking()
    }
}
```

**Data Structure (COMMON):**

**Location:** `common/src/main/java/com/Pulsify/data/TrackedData.kt`

```kotlin
@Serializable
data class TrackedData(
    var hr: Int = 0,                      // Heart Rate (BPM)
    var ibi: ArrayList<Int> = ArrayList() // Inter-Beat Intervals (ms)
)
```

---

### **PHASE 5: Data Transmission to Phone (WEAR)**

**Location:** `wear/src/main/java/com/Pulsify/domain/SendMessageUseCase.kt`

```kotlin
private const val MESSAGE_PATH = "/msg"

class SendMessageUseCase @Inject constructor(
    private val messageRepository: MessageRepository,
    private val trackingRepository: TrackingRepository,
    private val getCapableNodes: GetCapableNodes
) {
    suspend operator fun invoke(): Boolean {
        val nodes = getCapableNodes() // Discover connected phones
        
        return if (nodes.isNotEmpty()) {
            val node = nodes.first()
            val message = encodeMessage(trackingRepository.getValidHrData())
            messageRepository.sendMessage(message, node, MESSAGE_PATH)
            true
        } else {
            Log.i(TAG, "Ain't no nodes around")
            false
        }
    }

    fun encodeMessage(trackedData: ArrayList<TrackedData>): String {
        return Json.encodeToString(trackedData) // Serialize to JSON
    }
}
```

**Node Discovery Process:**

**Location:** `wear/src/main/java/com/Pulsify/domain/GetCapableNodes.kt`

```kotlin
private const val CAPABILITY = "wear"

class GetCapableNodes @Inject constructor(
    private val capabilityRepository: CapabilityRepository
) {
    suspend operator fun invoke(): Set<Node> {
        return capabilityRepository.getNodesForCapability(
            CAPABILITY,
            capabilityRepository.getCapabilitiesForReachableNodes()
        )
    }
}
```

**Message Sending:**

**Location:** `wear/src/main/java/com/Pulsify/data/MessageRepositoryImpl.kt`

```kotlin
override suspend fun sendMessage(message: String, node: Node, messagePath: String): Boolean {
    val nodeId = node.id
    var result = false
    
    nodeId.also { id ->
        messageClient
            .sendMessage(
                id,
                messagePath,
                message.toByteArray(charset = Charset.defaultCharset())
            ).apply {
                addOnSuccessListener {
                    Log.i(TAG, "sendMessage OnSuccessListener")
                    result = true
                }
                addOnFailureListener {
                    Log.i(TAG, "sendMessage OnFailureListener")
                    result = false
                }
            }.await()
        return result
    }
}
```

**Transmission Protocol:**
- **Transport**: Google Wearable Data Layer (MessageClient)
- **Message Path**: `/msg`
- **Format**: JSON-serialized array of TrackedData
- **Encoding**: UTF-8 byte array
- **Network**: Bluetooth or WiFi Direct

---

### **PHASE 6: Message Reception on Phone (MOBILE)**

**Location:** `mobile/src/main/java/com/Pulsify/mobile/data/DataListenerService.kt`

```kotlin
private const val TAG = "DataListenerService"
private const val MESSAGE_PATH = "/msg"

class DataListenerService : WearableListenerService() {
    override fun onMessageReceived(messageEvent: MessageEvent) {
        super.onMessageReceived(messageEvent)

        val value = messageEvent.data.decodeToString()
        Log.i(TAG, "onMessageReceived(): $value")
        
        when (messageEvent.path) {
            MESSAGE_PATH -> {
                Log.i(TAG, "Service: message (/msg) received: $value")

                if (value != "") {
                    // Launch MainActivity with data
                    startActivity(
                        Intent(this, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            .putExtra("message", value)
                    )
                } else {
                    Log.i(TAG, "value is an empty string")
                }
            }
        }
    }
}
```

**Service Registration (MOBILE):**

**Location:** `mobile/src/main/AndroidManifest.xml`

```xml
<service
    android:name="com.Pulsify.mobile.data.DataListenerService"
    android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.DATA_CHANGED" />
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <action android:name="com.google.android.gms.wearable.REQUEST_RECEIVED" />
        <action android:name="com.google.android.gms.wearable.CAPABILITY_CHANGED" />
        <action android:name="com.google.android.gms.wearable.CHANNEL_EVENT" />
        
        <data
            android:host="*"
            android:pathPrefix="/msg"
            android:scheme="wear" />
    </intent-filter>
</service>
```

**Key Points:**
- **Background Service**: Always running to listen for messages
- **Exported**: Allows system (Wearable Data Layer) to send messages
- **Intent Filters**: Catches MESSAGE_RECEIVED events on `/msg` path

---

### **PHASE 7: Data Decoding & Display (MOBILE)**

**Location:** `mobile/src/main/java/com/Pulsify/mobile/presentation/MainActivity.kt`

```kotlin
@Composable
fun TheApp(intent: Intent?) {
    if (intent?.getStringExtra("message") != null) {
        val txt = intent.getStringExtra("message").toString()
        
        // Decode JSON message
        val measurementResults = HelpFunctions.decodeMessage(txt)
        
        // Display in UI
        MainScreen(measurementResults)
    }
}
```

**Decoding Logic:**

**Location:** `mobile/src/main/java/com/Pulsify/mobile/presentation/HelpFunctions.kt`

```kotlin
class HelpFunctions {
    companion object {
        fun decodeMessage(message: String): List<TrackedData> {
            return Json.decodeFromString(message)
        }
    }
}
```

---

## 🔑 Key Differences: Kotlin vs Flutter Method Channel

### **1. Health Permissions - CRITICAL DIFFERENCE**

| Aspect | Kotlin Native (THIS IMPLEMENTATION) | Flutter Method Channel |
|--------|-------------------------------------|------------------------|
| **Permission Handling** | ✅ **Built-in at OS level**<br/>• `Permission.kt` wrapper<br/>• Android Manifest declarations<br/>• Automatic permission dialog<br/>• Lifecycle-aware requests | ❌ **Manual implementation needed**<br/>• Must create custom permission plugin<br/>• Flutter doesn't have direct health sensor access<br/>• Requires platform channel bridge |
| **Permission Types** | ✅ **Version-aware**<br/>• Android 14-: `BODY_SENSORS`<br/>• Android 15+: `health.READ_HEART_RATE`<br/>• Automatically selected at runtime | ⚠️ **Complex to implement**<br/>• Must manually check Android version<br/>• Must handle both permission types<br/>• Requires native Kotlin/Java code anyway |
| **Permission UI** | ✅ **Compose-native Permission UI**<br/>• `rememberMultiplePermissionsState()`<br/>• Rationale display<br/>• Permanent denial handling | ❌ **Must build custom UI**<br/>• No built-in permission UI<br/>• Hard to match native UX |
| **Permission Flow** | ✅ **Seamless integration**<br/>• `DisposableEffect` + `LifecycleEventObserver`<br/>• Automatic re-check on lifecycle events | ⚠️ **Manual state management**<br/>• Must manually track lifecycle<br/>• Risk of missing permission checks |

### **2. Samsung Health SDK Integration**

| Aspect | Kotlin Native | Flutter Method Channel |
|--------|---------------|------------------------|
| **SDK Access** | ✅ **Direct API access**<br/>• `HealthTrackingService`<br/>• `HealthTracker`<br/>• Type-safe callbacks | ❌ **Indirect via bridge**<br/>• Must create platform channel<br/>• JSON serialization overhead<br/>• Lost type safety |
| **Real-time Streaming** | ✅ **Native Kotlin Flow**<br/>• `callbackFlow`<br/>• Coroutines<br/>• Efficient memory | ⚠️ **EventChannel complexity**<br/>• Must manually manage streams<br/>• More overhead |
| **Error Handling** | ✅ **Sealed classes**<br/>• `TrackerMessage` hierarchy<br/>• Pattern matching<br/>• Compile-time safety | ❌ **String-based errors**<br/>• Must encode/decode error types<br/>• Runtime checks only |

### **3. Data Transmission**

| Aspect | Kotlin Native | Flutter Method Channel |
|--------|---------------|------------------------|
| **Wearable Data Layer** | ✅ **Direct MessageClient**<br/>• `sendMessage()` API<br/>• Node discovery<br/>• Capability checking | ❌ **Must create platform plugin**<br/>• Bridge overhead<br/>• Complex async handling |
| **Serialization** | ✅ **Kotlinx Serialization**<br/>• `@Serializable` annotations<br/>• Compile-time checks<br/>• Shared data classes | ⚠️ **JSON manual mapping**<br/>• Must define schemas twice<br/>• Runtime parsing errors |
| **Background Service** | ✅ **Native Service**<br/>• `WearableListenerService`<br/>• Always-on listening<br/>• OS-managed lifecycle | ❌ **Flutter isolates complex**<br/>• Must use native service anyway<br/>• Method channel from background tricky |

### **4. Architecture & Performance**

| Aspect | Kotlin Native | Flutter Method Channel |
|--------|---------------|------------------------|
| **Dependency Injection** | ✅ **Hilt**<br/>• Compile-time DI<br/>• Scoped instances<br/>• Clean architecture | ⚠️ **Manual DI**<br/>• Flutter's `get_it` or `provider`<br/>• Must bridge to native DI |
| **State Management** | ✅ **StateFlow + Compose**<br/>• Reactive streams<br/>• Lifecycle-aware<br/>• Memory efficient | ⚠️ **Flutter state + platform channel**<br/>• Two separate state systems<br/>• Synchronization issues |
| **Performance** | ✅ **Zero overhead**<br/>• Direct native calls<br/>• No serialization for internal ops | ❌ **Multiple layers**<br/>• Dart → Platform Channel → Kotlin<br/>• JSON serialize/deserialize<br/>• Significant overhead |

### **5. Why Permissions Are Missing in Flutter**

**The Core Issue:**

```
Flutter (Dart)
    ↓ [Platform Channel Bridge]
Kotlin/Java (Native Android)
    ↓ [Samsung Health SDK]
Heart Rate Sensor
```

**Flutter CANNOT directly access:**
- Android permission system (for health sensors)
- Samsung Health SDK APIs
- Wearable Data Layer APIs

**You MUST use native Kotlin/Java code**, meaning:
- You'd need to write the SAME Kotlin code anyway
- Flutter just adds an extra layer
- Health permissions still need `Permission.kt` or equivalent
- No advantage gained from Flutter for smartwatch health tracking

---

## 📦 Module Responsibilities

### **COMMON Module**
- **Purpose**: Shared data models between wear and mobile
- **Key Files**:
  - `TrackedData.kt`: Serializable data class for HR and IBI
- **Why**: Single source of truth for data structure

### **WEAR Module (Smartwatch)**
- **Purpose**: Collect health data and transmit to phone
- **Layers**:
  1. **Presentation**: UI, permissions, user interaction
  2. **Domain**: Business logic, use cases
  3. **Data**: Samsung Health SDK, Wearable Data Layer
- **Dependencies**:
  - Samsung Health Sensor API (AAR)
  - Google Play Services Wearable
  - Hilt for DI
  - Compose for UI
  - Accompanist Permissions

### **MOBILE Module (Phone)**
- **Purpose**: Receive and display health data
- **Components**:
  1. **DataListenerService**: Background listener
  2. **MainActivity**: UI display
  3. **HelpFunctions**: Data decoding
- **Dependencies**:
  - Google Play Services Wearable
  - Hilt for DI
  - Compose for UI

---

## ⚡ Live Data Flow Example

### **Scenario: User Starts Heart Rate Tracking**

```
TIME    | WEAR (Smartwatch)                          | MOBILE (Phone)
--------|--------------------------------------------|------------------
00:00   | User opens app                            |
00:01   | Permission.kt checks permissions          |
00:02   | Permission dialog shown                    |
00:03   | User grants BODY_SENSORS permission       |
00:04   | MainActivity.onCreate() → setUpTracking() |
00:05   | Connect to Samsung Health Service          |
00:06   | Connection SUCCESS                         |
00:07   | User taps "START" button                   |
00:08   | startTracking() called                     |
00:09   | TrackingRepository.track() initiated       |
00:10   | HealthTracker listener registered          |
00:11   | FIRST HEARTBEAT DETECTED                   |
00:12   | onDataReceived() → HR=72, IBI=[850,840]   |
00:13   | TrackerMessage.DataMessage emitted         |
00:14   | MainViewModel.processExerciseUpdate()      |
00:15   | UI updates: HR=72 displayed                |
00:16   | Data stored in validHrData list            |
--------|--------------------------------------------|------------------
00:17   | User taps "SEND" button                    |
00:18   | sendMessage() called                       |
00:19   | GetCapableNodes() discovers phone          |
00:20   | Phone node found: Node(id=abc123)          |
00:21   | Encode last 40 HR values to JSON           |
00:22   | MessageRepository.sendMessage()            |
00:23   | Data sent via Bluetooth                    |
--------|--------------------------------------------|------------------
00:24   |                                            | DataListenerService
        |                                            |   .onMessageReceived()
00:25   |                                            | JSON decoded
00:26   |                                            | MainActivity launched
00:27   |                                            | HelpFunctions.decode()
00:28   |                                            | MainScreen displays
        |                                            |   List<TrackedData>
00:29   |                                            | User sees HR history
--------|--------------------------------------------|------------------
00:30   | CONTINUOUS TRACKING                        |
00:31   | HR=73, IBI=[845,835,830]                  |
00:32   | HR=74, IBI=[840,830,825]                  |
...     | (Updates every ~1 second)                 |
```

---

## 🛠️ Build Configuration

### **Wear Module - build.gradle**
```gradle
dependencies {
    // Samsung Health SDK (CRITICAL for heart rate access)
    implementation fileTree(dir: 'libs', include: '*.aar')
    
    // Wearable Data Layer
    implementation 'com.google.android.gms:play-services-wearable:19.0.0'
    
    // Permissions UI
    implementation 'com.google.accompanist:accompanist-permissions:0.37.3'
    
    // Dependency Injection
    implementation "com.google.dagger:hilt-android:$hilt_version"
    ksp "com.google.dagger:hilt-compiler:$hilt_version"
    
    // Serialization
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0'
    
    // Compose for Wear OS
    implementation "androidx.wear.compose:compose-material:$wear_compose_version"
    
    // Shared data models
    implementation project(':common')
}
```

### **Mobile Module - build.gradle**
```gradle
dependencies {
    // Wearable Data Layer
    implementation 'com.google.android.gms:play-services-wearable:19.0.0'
    
    // Dependency Injection
    implementation "com.google.dagger:hilt-android:$hilt_version"
    ksp "com.google.dagger:hilt-compiler:$hilt_version"
    
    // Serialization
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0'
    
    // Compose UI
    implementation "androidx.compose.ui:ui:$compose_version"
    implementation 'androidx.compose.material3:material3:1.3.2'
    
    // Shared data models
    implementation project(':common')
}
```

---

## 🎯 Summary: Why This Works

### **✅ Advantages of Native Kotlin Implementation**

1. **Health Permissions Built-in**
   - OS-level permission system integration
   - Automatic permission dialogs
   - Lifecycle-aware permission requests
   - No extra bridge code needed

2. **Direct SDK Access**
   - Samsung Health SDK native APIs
   - Type-safe callbacks
   - Zero serialization overhead internally
   - Real-time data streaming with Kotlin Flow

3. **Clean Architecture**
   - MVVM + Clean Architecture
   - Hilt dependency injection
   - Repository pattern
   - Testable code

4. **Performance**
   - Native execution speed
   - Efficient memory usage
   - No platform channel overhead
   - Direct hardware access

5. **Wearable Data Layer Integration**
   - Native MessageClient API
   - Background service for always-on listening
   - Node discovery and capability checking
   - Reliable data transmission

### **⚠️ What's Missing in Flutter Approach**

1. **No Direct Permission Access**
   - Must create platform channel for permissions
   - Still need native Kotlin code
   - Duplicate permission logic

2. **Samsung Health SDK Not Available**
   - No Dart bindings exist
   - Must use platform channels
   - Complex async bridging

3. **Wearable Data Layer Complexity**
   - Must create custom plugin
   - Background service still needs native code
   - Method channel overhead

4. **State Synchronization Issues**
   - Two separate state management systems
   - Potential race conditions
   - Harder to debug

---

## 📱 Testing the Flow

### **On Smartwatch:**
1. Install app
2. Grant BODY_SENSORS permission (critical!)
3. Wait for "Connected to Health Tracking Service"
4. Tap START - see heart rate appear
5. Wait 30 seconds for data collection
6. Tap SEND - "Sending success" toast appears

### **On Phone:**
1. Install app
2. Ensure Bluetooth enabled and paired
3. App launches automatically when data received
4. See list of HR and IBI values

---

## 🚀 Next Steps for Flutter Integration

If you want to compare with Flutter method channels:

1. **Create Platform Channel in Flutter**
   ```dart
   static const platform = MethodChannel('com.Pulsify/health');
   ```

2. **On Native Side (Kotlin):**
   ```kotlin
   // Still need Permission.kt
   // Still need TrackingRepository
   // Still need Samsung Health SDK
   // Just add MethodChannel bridge on top
   ```

3. **Realize the overhead:**
   - You still write all the Kotlin code above
   - Then add Flutter bridge layer
   - No benefit for smartwatch health tracking

---

## 📄 File Reference

### **WEAR Module Key Files:**
- `wear/src/main/java/com/Pulsify/presentation/ui/Permission.kt` - **PERMISSION HANDLING**
- `wear/src/main/java/com/Pulsify/presentation/MainActivity.kt` - Entry point
- `wear/src/main/java/com/Pulsify/presentation/MainViewModel.kt` - State management
- `wear/src/main/java/com/Pulsify/data/TrackingRepositoryImpl.kt` - Samsung Health SDK
- `wear/src/main/java/com/Pulsify/data/MessageRepositoryImpl.kt` - Wearable messages
- `wear/src/main/java/com/Pulsify/domain/SendMessageUseCase.kt` - Send logic
- `wear/src/main/AndroidManifest.xml` - **PERMISSION DECLARATIONS**

### **MOBILE Module Key Files:**
- `mobile/src/main/java/com/Pulsify/mobile/data/DataListenerService.kt` - Message receiver
- `mobile/src/main/java/com/Pulsify/mobile/presentation/MainActivity.kt` - UI display
- `mobile/src/main/java/com/Pulsify/mobile/presentation/HelpFunctions.kt` - JSON decoder
- `mobile/src/main/AndroidManifest.xml` - Service registration

### **COMMON Module Key Files:**
- `common/src/main/java/com/Pulsify/data/TrackedData.kt` - Shared data model

---

## 🔒 Security & Privacy Notes

1. **Permissions are requested, not assumed**
2. **Health data stays local** - only sent when user taps SEND
3. **Data is ephemeral** - only last 40 values kept in memory
4. **No cloud storage** - direct watch-to-phone transmission
5. **User has full control** - can deny permissions, stop tracking anytime

---

## 📊 Monitoring & Debugging

### **Wear Logs:**
```bash
adb -s <watch_device> logcat | grep -E "MainActivity|MainViewModel|TrackingRepository|Permission"
```

### **Mobile Logs:**
```bash
adb -s <phone_device> logcat | grep -E "DataListenerService|MainActivity"
```

### **Check Permissions:**
```bash
adb shell dumpsys package com.pulsify.app | grep permission
```

---

**Generated:** November 25, 2025  
**Status:** ✅ **WORKING IMPLEMENTATION** - Live data successfully flowing from smartwatch to phone  
**Critical Component:** Health permissions properly requested and managed in Wear OS layer
