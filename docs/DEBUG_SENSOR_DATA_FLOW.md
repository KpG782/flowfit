# Sensor Data Flow Debug Guide

## What to Check on the Watch

### 1. Watch Logs - Accelerometer Collection
Look for these log messages when tracking is active:

```
✅ EXPECTED LOGS:
I/HealthTrackingManager: Accelerometer tracking started successfully
I/WatchSensorService: 🚀 Accelerometer tracking STARTED at [timestamp]
I/WatchSensorService: 📊 Sensor collected at [timestamp]: X=..., Y=..., Z=..., buffer=1/32
I/WatchSensorService: 📊 Sensor collected at [timestamp]: X=..., Y=..., Z=..., buffer=2/32
...
I/WatchSensorService: 📊 Sensor collected at [timestamp]: X=..., Y=..., Z=..., buffer=32/32
```

### 2. Watch Logs - Batch Transmission
After collecting 32 samples, look for:

```
✅ EXPECTED LOGS:
I/WatchSensorService: 📤 Preparing batch transmission at [timestamp]: batch_size=32, bpm=[HR], sample_rate=32Hz
I/WatchSensorService: 📦 JSON packet created: size=[bytes] bytes, samples=32
I/WatchSensorService: 📱 Sending to phone node: [phone name] ([node id])
I/WatchSensorService: ✅ Batch transmission SUCCESS: node=[phone], samples=32, bpm=[HR], size=[bytes]B, time=[ms]ms
```

### 3. Watch Logs - Potential Issues
If you see these, there's a problem:

```
❌ PROBLEM LOGS:
W/WatchSensorService: ⚠️ PHONE DISCONNECTED: No connected phone nodes found - batch discarded
E/WatchSensorService: ❌ Batch transmission FAILED: error=[error message]
E/WatchSensorService: ❌ SENSOR ERROR: Accelerometer not available
```

## What to Check on the Phone

### 1. Phone Logs - Event Channel Registration
At app start, you should see:

```
✅ EXPECTED LOGS:
I/MainActivity: Phone data listener event sink registered
I/MainActivity: Sensor batch event sink registered
```

### 2. Phone Logs - Data Reception
When watch sends data, look for:

```
✅ EXPECTED LOGS FOR HEART RATE:
I/PhoneDataListener: Message received from watch
I/PhoneDataListener: Path: /heart_rate
I/PhoneDataListener: Heart rate data received: {"bpm":72,...}
I/PhoneDataListener: Data sent to Flutter successfully

✅ EXPECTED LOGS FOR SENSOR BATCH:
I/PhoneDataListener: Message received from watch
I/PhoneDataListener: Path: /sensor_data
I/PhoneDataListener: Sensor batch data received: {"type":"sensor_batch","count":32,...}
I/PhoneDataListener: Sensor batch data sent to Flutter successfully
```

### 3. Phone UI Logs - Flutter Side
In the Flutter logs, look for:

```
✅ EXPECTED LOGS:
I/flutter: 📦 Received sensor batch: 32 samples, BPM: 72
```

## Current Status Based on Your Logs

### ✅ Working:
- Phone event channels registered
- Heart rate data being received on phone
- Heart rate data sent to Flutter successfully

### ❌ Missing:
- No `/sensor_data` messages in phone logs
- No "Sensor batch data received" messages
- No Flutter logs showing sensor batch reception

## Debugging Steps

### Step 1: Check Watch is Sending
Run the watch app with `flutter run -d [watch-device-id]` and look for:
1. "Accelerometer tracking started successfully"
2. "Sensor collected" messages (should see 32 of them)
3. "Batch transmission SUCCESS" messages

### Step 2: Check Phone is Receiving
While watch is running, check phone logs for:
1. "Path: /sensor_data" messages
2. "Sensor batch data received" messages

### Step 3: Check UI Display
1. Open phone app
2. Navigate to "Watch Heart Rate Data" screen
3. Click the bug icon (top right) to enable Test Mode
4. You should see:
   - Total Batches Received: [number]
   - Sample Count: 32
   - Heart Rate: [BPM]
   - Accelerometer Samples with X, Y, Z values

## Quick Test Commands

### Watch Side:
```bash
# Run watch app and filter for sensor logs
flutter run -d [watch-device-id] | grep -E "WatchSensorService|Accelerometer"
```

### Phone Side:
```bash
# Run phone app and filter for sensor batch logs
flutter run -d [phone-device-id] | grep -E "sensor_data|Sensor batch"
```

## Expected Data Flow

```
WATCH                           PHONE
-----                           -----
1. Start tracking
2. Collect accelerometer        
   (32 samples @ 32Hz)
3. Create JSON batch
4. Send via /sensor_data  -->   5. Receive on /sensor_data path
                                6. Parse JSON to Map
                                7. Send to Flutter EventChannel
                                8. Update UI with XYZ data
```

## Troubleshooting

### If watch shows "PHONE DISCONNECTED":
- Check both devices are on same network
- Check Bluetooth is enabled
- Check Galaxy Wearable app is connected

### If phone receives /heart_rate but not /sensor_data:
- Check WatchSensorService.startTracking() is being called
- Check for accelerometer permission errors
- Check buffer is filling up (should see 32 samples)

### If phone receives data but UI shows 0:
- Check Test Mode is enabled (bug icon)
- Check _lastSensorBatch is being updated
- Check accelerometer array parsing in _buildAccelerometerSamples()
