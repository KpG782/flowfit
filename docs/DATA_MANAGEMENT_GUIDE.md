# FlowFit Data Management Guide

## Overview
Complete guide for managing heart rate, IBI, and HRV data from Galaxy Watch to Flutter app with local database storage and backend sync.

---

## Architecture

```
Galaxy Watch (Kotlin)
    ↓ Wearable Data Layer
Flutter Phone App
    ↓
HeartRateDataManager (In-Memory Buffer)
    ↓
DatabaseService (SQLite)
    ↓
DataSyncManager (Backend Sync)
    ↓
Supabase/Backend
```

---

## Data Flow

### 1. Data Reception
```dart
PhoneDataListener → HeartRateData → TrackedData → HeartRateDataManager
```

### 2. Buffer Management
- **Max Buffer Size:** 100 records
- **Auto-flush:** When buffer reaches max size
- **Force-flush:** On app close/background

### 3. Database Storage
- **Max Records:** 10,000
- **Auto-cleanup:** Deletes old synced data when limit reached
- **Retention:** 30 days for synced data

### 4. Backend Sync
- **Frequency:** Every 15 minutes
- **Strategy:** Upload unsynced records only
- **Retry:** Automatic on failure

---

## Key Components

### TrackedData Model
```dart
class TrackedData {
  final int hr;                    // Heart Rate (BPM)
  final List<int> ibiValues;       // Inter-Beat Intervals (ms)
  final double hrv;                // Heart Rate Variability (RMSSD)
  final int spo2;                  // Blood Oxygen (%)
  final DateTime timestamp;
  final SensorStatus status;
}
```

### IBI History Manager
```dart
class IbiHistoryManager {
  final int maxHistorySize = 10;  // Rolling window
  
  // Maintains last 10 IBI values for stable HRV calculation
  // Matches Kotlin implementation behavior
}
```

### Heart Rate Data Manager
```dart
class HeartRateDataManager {
  final int maxBufferSize = 100;
  final int maxDatabaseRecords = 10000;
  
  // Features:
  // - In-memory buffer
  // - Auto-flush to database
  // - Real-time stream
  // - IBI history tracking
  // - HRV calculation
}
```

### Database Service
```dart
class DatabaseService {
  // Tables:
  // - heart_rate_data (main table)
  
  // Indexes:
  // - timestamp (DESC) - for recent queries
  // - synced - for sync queries
  
  // Features:
  // - Batch insert
  // - Date range queries
  // - Sync status tracking
  // - Auto-cleanup
}
```

### Data Sync Manager
```dart
class DataSyncManager {
  // Features:
  // - Periodic sync (every 15 min)
  // - Upload unsynced data
  // - Mark as synced
  // - Error handling
}
```

---

## Best Practices

### 1. Data Reception
```dart
// Convert HeartRateData to TrackedData
final trackedData = TrackedData(
  hr: heartRateData.bpm ?? 0,
  ibiValues: heartRateData.ibiValues,
  hrv: TrackedData.calculateHRV(heartRateData.ibiValues),
  spo2: 0,
  timestamp: heartRateData.timestamp,
  status: heartRateData.status,
);

// Add to data manager
await _dataManager.addData(trackedData);
```

### 2. Buffer Management
```dart
// Auto-flush when buffer is full
if (_dataBuffer.length >= maxBufferSize) {
  await _flushBuffer();
}

// Force flush before app closes
@override
void dispose() {
  _dataManager.forceFlush();
  super.dispose();
}
```

### 3. Database Queries
```dart
// Get recent data (combines buffer + database)
final recentData = await _dataManager.getRecentData(limit: 50);

// Get data by date range
final data = await _dataManager.getDataByDateRange(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

### 4. Backend Sync
```dart
// Start periodic sync
_syncManager.startPeriodicSync(
  interval: Duration(minutes: 15),
);

// Manual sync
await _syncManager.syncData();

// Stop sync
_syncManager.stopPeriodicSync();
```

---

## Database Schema

### heart_rate_data Table
```sql
CREATE TABLE heart_rate_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hr INTEGER NOT NULL,
  ibi_values TEXT,              -- Comma-separated IBI values
  hrv REAL NOT NULL,
  spo2 INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  status TEXT NOT NULL,
  synced INTEGER DEFAULT 0,     -- 0 = not synced, 1 = synced
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_timestamp ON heart_rate_data(timestamp DESC);
CREATE INDEX idx_synced ON heart_rate_data(synced);
```

---

## IBI & HRV Implementation

### IBI Collection (from Kotlin)
```kotlin
// Kotlin side sends:
{
  "hr": 78,
  "ibi": [845, 777, 729],
  "hrv": 68.0,
  "spo2": 0,
  "timestamp": 1732545971348
}
```

### Flutter Reception
```dart
// Parse IBI values
final ibiList = json['ibi'] ?? [];
final List<int> ibiValues = ibiList is List
    ? ibiList.map((e) => e as int).toList()
    : [];

// Calculate HRV if not provided
double hrv = json['hrv'] ?? 0.0;
if (hrv == 0.0 && ibiValues.length >= 2) {
  hrv = TrackedData.calculateHRV(ibiValues);
}
```

### HRV Calculation (RMSSD)
```dart
static double calculateHRV(List<int> ibiList) {
  if (ibiList.length < 2) return 0.0;

  // Calculate RMSSD
  final differences = <double>[];
  for (int i = 0; i < ibiList.length - 1; i++) {
    final diff = ibiList[i + 1] - ibiList[i];
    differences.add(diff * diff.toDouble());
  }

  final average = differences.reduce((a, b) => a + b) / differences.length;
  return sqrt(average);
}
```

### Rolling IBI History
```dart
class IbiHistoryManager {
  final List<int> _ibiHistory = [];
  final int maxHistorySize = 10;

  void addIbiValues(List<int> newValues) {
    _ibiHistory.addAll(newValues);
    
    // Keep only last 10 values
    while (_ibiHistory.length > maxHistorySize) {
      _ibiHistory.removeAt(0);
    }
  }

  double calculateHRV() {
    return TrackedData.calculateHRV(_ibiHistory);
  }
}
```

---

## UI Display

### Current Heart Rate Card
```dart
// Display HR
Text('$bpm BPM')

// Display HRV
if (hrv > 0) {
  Text('HRV: ${hrv.toStringAsFixed(1)} ms')
}

// Display IBI values
if (ibiValues.isNotEmpty) {
  Text('IBI: ${ibiValues.take(5).join(", ")} ms')
}
```

### Recent Readings List
```dart
ListTile(
  title: Text('${data.hr} BPM'),
  subtitle: Text(
    'HRV: ${data.hrv.toStringAsFixed(1)} ms • '
    'IBI: ${data.ibiValues.length} • '
    '$timeAgo'
  ),
)
```

---

## Performance Optimization

### 1. Buffer Size
- **100 records** = ~2-3 minutes of data at 1 Hz
- Reduces database writes
- Balances memory usage

### 2. Database Limits
- **10,000 records** = ~2-3 hours of continuous data
- Auto-cleanup prevents unlimited growth
- Keeps app responsive

### 3. Sync Frequency
- **15 minutes** = Good balance for battery and data freshness
- Reduces network usage
- Ensures data safety

### 4. Query Optimization
- Indexes on `timestamp` and `synced`
- Limit queries to recent data
- Combine buffer + database results

---

## Error Handling

### 1. Data Reception Errors
```dart
_heartRateSubscription = _dataListener.heartRateStream.listen(
  (data) { /* handle data */ },
  onError: (error) {
    _logger.e('Stream error: $error');
    setState(() {
      _statusMessage = 'Error: $error';
      _isConnected = false;
    });
  },
);
```

### 2. Database Errors
```dart
try {
  await _dbService.insertHeartRateData(data);
} catch (e, stackTrace) {
  _logger.e('Database error', error: e, stackTrace: stackTrace);
  // Data stays in buffer, will retry on next flush
}
```

### 3. Sync Errors
```dart
try {
  await _syncManager.syncData();
} catch (e) {
  _logger.e('Sync error: $e');
  // Data remains marked as unsynced, will retry next cycle
}
```

---

## Testing

### 1. Test Data Flow
```dart
// Add test data
final testData = TrackedData(
  hr: 75,
  ibiValues: [800, 820, 790],
  hrv: 15.0,
  spo2: 98,
  timestamp: DateTime.now(),
  status: SensorStatus.active,
);

await _dataManager.addData(testData);

// Verify buffer
expect(_dataManager.bufferSize, 1);

// Verify database
final recent = await _dataManager.getRecentData(limit: 1);
expect(recent.first.hr, 75);
```

### 2. Test Buffer Flush
```dart
// Add 100 records
for (int i = 0; i < 100; i++) {
  await _dataManager.addData(testData);
}

// Buffer should auto-flush
expect(_dataManager.bufferSize, 0);

// Database should have 100 records
final stats = await _dbService.getStatistics();
expect(stats['total_records'], 100);
```

### 3. Test IBI/HRV
```dart
// Test HRV calculation
final ibiValues = [800, 820, 790, 810, 795];
final hrv = TrackedData.calculateHRV(ibiValues);
expect(hrv, greaterThan(0));

// Test rolling history
final ibiManager = IbiHistoryManager();
ibiManager.addIbiValues([800, 820]);
expect(ibiManager.size, 2);
expect(ibiManager.hasEnoughData, true);
```

---

## Monitoring

### Statistics
```dart
final stats = _dataManager.getStatistics();
print('Total received: ${stats['total_received']}');
print('Total saved: ${stats['total_saved']}');
print('Buffer size: ${stats['buffer_size']}');
print('IBI history: ${stats['ibi_history_size']}');
print('Current HRV: ${stats['current_hrv']}');
```

### Database Stats
```dart
final dbStats = await _dbService.getStatistics();
print('Total records: ${dbStats['total_records']}');
print('Unsynced: ${dbStats['unsynced_records']}');
print('Oldest: ${dbStats['oldest_record']}');
print('Newest: ${dbStats['newest_record']}');
```

---

## Cleanup & Maintenance

### 1. Clear Old Data
```dart
// Delete data older than 30 days (synced only)
final deleted = await _dbService.deleteOldData(daysToKeep: 30);
print('Deleted $deleted old records');
```

### 2. Clear All Data
```dart
// Clear everything (use with caution)
await _dataManager.clearAllData();
```

### 3. Force Flush
```dart
// Flush buffer before app closes
await _dataManager.forceFlush();
```

---

## Backend Integration (Supabase)

### 1. Setup Supabase Table
```sql
CREATE TABLE heart_rate_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  hr INTEGER NOT NULL,
  ibi_values INTEGER[],
  hrv REAL NOT NULL,
  spo2 INTEGER NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_timestamp ON heart_rate_data(user_id, timestamp DESC);
```

### 2. Sync Implementation
```dart
Future<bool> syncData() async {
  final unsyncedData = await _dbService.getUnsyncedData();
  if (unsyncedData.isEmpty) return true;

  try {
    // Convert to Supabase format
    final supabaseData = unsyncedData.map((data) => {
      'user_id': currentUserId,
      'hr': data['hr'],
      'ibi_values': data['ibi_values'].split(',').map(int.parse).toList(),
      'hrv': data['hrv'],
      'spo2': data['spo2'],
      'timestamp': DateTime.fromMillisecondsSinceEpoch(data['timestamp']).toIso8601String(),
      'status': data['status'],
    }).toList();

    // Upload to Supabase
    await supabase.from('heart_rate_data').insert(supabaseData);

    // Mark as synced
    final ids = unsyncedData.map((d) => d['id'] as int).toList();
    await _dbService.markAsSynced(ids);

    return true;
  } catch (e) {
    _logger.e('Sync error: $e');
    return false;
  }
}
```

---

## Summary

### ✅ Implemented Features
1. **In-memory buffer** with auto-flush
2. **SQLite database** with indexes
3. **IBI & HRV** tracking and calculation
4. **Rolling IBI history** (10 values)
5. **Data sync manager** with periodic upload
6. **Auto-cleanup** of old data
7. **Error handling** at all levels
8. **Statistics** and monitoring

### 📊 Data Limits
- **Buffer:** 100 records (~2-3 minutes)
- **Database:** 10,000 records (~2-3 hours)
- **Retention:** 30 days for synced data
- **Sync:** Every 15 minutes

### 🎯 Best Practices
1. Always flush buffer before app closes
2. Monitor database size regularly
3. Handle sync errors gracefully
4. Keep IBI history for stable HRV
5. Use indexes for fast queries
6. Batch operations when possible

---

**Last Updated:** November 25, 2025
**Status:** ✅ Production Ready
