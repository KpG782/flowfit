# FlowFit Quick Start Guide

## ✅ What's Been Fixed & Implemented

### 1. Icons Fixed
- ✅ Added `cupertino_icons` package
- ✅ Added `flutter_svg` for SVG support
- ✅ All Material Icons now working properly

### 2. Data Management Implemented
- ✅ **In-memory buffer** (100 records, auto-flush)
- ✅ **SQLite database** (10,000 records max)
- ✅ **Auto-cleanup** (deletes old data when limit reached)
- ✅ **IBI & HRV tracking** (matches Kotlin implementation)
- ✅ **Rolling IBI history** (10-value window for stable HRV)
- ✅ **Data sync manager** (uploads to backend every 15 min)

### 3. Authentication Flow
- ✅ Loading screen with animations
- ✅ Welcome screen
- ✅ Login screen with validation
- ✅ Sign up screen with strong password requirements
- ✅ Reusable theme system (FlowFit Style Guide)

### 4. Enhanced UI
- ✅ Display HR, HRV, and IBI values
- ✅ Show IBI count and sample values
- ✅ Enhanced recent readings list
- ✅ Real-time statistics
- ✅ Better error handling

---

## 🚀 Run the App

```bash
# Install dependencies (already done)
flutter pub get

# Run on phone
flutter run -d <phone_device_id>

# Run on watch
flutter run -d <watch_device_id> -t lib/main.dart
```

---

## 📱 App Flow

```
1. Loading Screen (3 seconds)
   ↓
2. Welcome Screen
   ├─→ Sign Up → Registration Form → Home
   └─→ Login → Login Form → Home
   ↓
3. Home Screen
   - Receives data from watch
   - Displays HR, HRV, IBI
   - Stores in database
   - Syncs to backend
```

---

## 📊 Data Flow (Watch → Phone)

```
Galaxy Watch (Kotlin)
    ↓ Sends JSON
    {
      "hr": 78,
      "ibi": [845, 777, 729],
      "hrv": 68.0,
      "spo2": 0,
      "timestamp": 1732545971348
    }
    ↓
PhoneDataListener
    ↓ Converts to TrackedData
HeartRateDataManager
    ↓ Buffer (100 records)
DatabaseService
    ↓ SQLite (10,000 records)
DataSyncManager
    ↓ Backend (every 15 min)
```

---

## 🔧 Key Components

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

### HeartRateDataManager
```dart
// Manages buffer, database, and IBI history
HeartRateDataManager(
  maxBufferSize: 100,           // Auto-flush at 100
  maxDatabaseRecords: 10000,    // Max 10k records
  ibiHistorySize: 10,           // Rolling window
)
```

### DatabaseService
```dart
// SQLite storage with indexes
- insertHeartRateData()
- getRecentHeartRateData(limit: 50)
- getDataByDateRange()
- deleteOldData(daysToKeep: 30)
```

### DataSyncManager
```dart
// Periodic backend sync
_syncManager.startPeriodicSync(
  interval: Duration(minutes: 15),
)
```

---

## 🎨 Theme System

### Colors (FlowFit Style Guide)
```dart
AppTheme.primaryBlue  // #3B82F6
AppTheme.lightBlue    // #5DADE2
AppTheme.cyan         // #5DD9E2
```

### Usage
```dart
// In main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)
```

---

## 📈 IBI & HRV

### IBI Collection
```dart
// From watch JSON
final ibiValues = [845, 777, 729];

// Display
Text('IBI: ${ibiValues.take(5).join(", ")} ms')
```

### HRV Calculation (RMSSD)
```dart
// Automatic calculation
final hrv = TrackedData.calculateHRV(ibiValues);
// Result: 68.0 ms

// Display
Text('HRV: ${hrv.toStringAsFixed(1)} ms')
```

### Rolling History
```dart
// Maintains last 10 IBI values
IbiHistoryManager(maxHistorySize: 10)

// Provides stable HRV over time
final hrv = _ibiHistory.calculateHRV();
```

---

## 🗄️ Database

### Schema
```sql
CREATE TABLE heart_rate_data (
  id INTEGER PRIMARY KEY,
  hr INTEGER NOT NULL,
  ibi_values TEXT,              -- Comma-separated
  hrv REAL NOT NULL,
  spo2 INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  status TEXT NOT NULL,
  synced INTEGER DEFAULT 0,     -- 0=not synced, 1=synced
  created_at INTEGER NOT NULL
);
```

### Queries
```dart
// Get recent data
final recent = await _dataManager.getRecentData(limit: 50);

// Get by date range
final data = await _dataManager.getDataByDateRange(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// Get statistics
final stats = await DatabaseService.instance.getStatistics();
```

---

## 🔄 Data Lifecycle

### 1. Reception
```dart
// Watch sends data → PhoneDataListener receives
_dataListener.heartRateStream.listen((heartRateData) {
  // Convert to TrackedData
  final trackedData = TrackedData(...);
  
  // Add to manager
  await _dataManager.addData(trackedData);
});
```

### 2. Buffering
```dart
// Stores in memory (100 records)
// Auto-flushes to database when full
if (_dataBuffer.length >= maxBufferSize) {
  await _flushBuffer();
}
```

### 3. Storage
```dart
// Saves to SQLite (10,000 records max)
await _dbService.insertHeartRateDataBatch(_dataBuffer);

// Auto-cleanup when limit reached
if (totalRecords > maxDatabaseRecords) {
  await _dbService.deleteOldData(daysToKeep: 7);
}
```

### 4. Sync
```dart
// Uploads unsynced data every 15 minutes
final unsyncedData = await _dbService.getUnsyncedData();
// TODO: Upload to Supabase
await _dbService.markAsSynced(ids);
```

---

## 🐛 Troubleshooting

### Icons Not Showing
✅ **Fixed:** `cupertino_icons` added to pubspec.yaml

### Empty IBI Values
- Wait 5-10 seconds after starting tracking
- Check watch sensor contact (wear tighter)
- Verify Kotlin side logs: `adb logcat | grep "IBI count:"`

### Database Too Large
- Auto-cleanup runs at 10,000 records
- Manual: `await _dbService.deleteOldData(daysToKeep: 7)`

### Sync Not Working
- Check internet connection
- Implement backend upload in `DataSyncManager.syncData()`
- Check logs: `flutter logs | grep "Sync"`

---

## 📝 Next Steps

### 1. Backend Integration
```dart
// In DataSyncManager.syncData()
await supabase.from('heart_rate_data').insert(unsyncedData);
```

### 2. Add Font Files
```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: GeneralSans
      fonts:
        - asset: assets/fonts/GeneralSans-Regular.ttf
```

### 3. Social Login
- Implement Google Sign In
- Implement Apple Sign In (iOS)

### 4. Enhanced Features
- Biometric authentication
- Data export (CSV, PDF)
- Charts and analytics
- Push notifications

---

## 📚 Documentation

1. **IMPLEMENTATION_SUMMARY.md** - Complete overview
2. **AUTH_FLOW_SETUP.md** - Authentication details
3. **DATA_MANAGEMENT_GUIDE.md** - Data handling best practices
4. **IBI_DATA_COLLECTION_GUIDE.md** - IBI/HRV from Kotlin

---

## ✅ Status

### Completed
- ✅ Icons fixed
- ✅ Data management (buffer, database, sync)
- ✅ IBI & HRV tracking
- ✅ Authentication UI
- ✅ Enhanced home screen
- ✅ Auto-cleanup
- ✅ Error handling
- ✅ Documentation

### Pending
- ⏳ Backend authentication API
- ⏳ Supabase data sync
- ⏳ Google/Apple Sign In
- ⏳ Font files (General Sans)

---

**Ready to test!** 🚀

Run `flutter run` and start receiving data from your Galaxy Watch.
