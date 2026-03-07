# Dual App Setup - Watch & Phone

## 🎯 Problem Solved

Pulsify has TWO separate apps:
1. **Watch App** - Runs on Galaxy Watch (Wear OS)
2. **Phone App** - Runs on Android Phone

They were getting mixed up because both were using the same entry point!

## ✅ Solution

### Separate Entry Points

**Watch App**:
- Entry: `lib/main_wear.dart`
- UI: Wear OS optimized (round screen, compact)
- Features: Heart rate tracking, Samsung Health SDK

**Phone App**:
- Entry: `lib/main.dart`
- UI: Material 3 (standard Android)
- Features: Data display, statistics, history

## 🚀 Correct Commands

### Run on Watch
```bash
# Use the script (recommended)
scripts\run_watch.bat

# Or manually
flutter run -d 6ece264d -t lib/main_wear.dart
```

### Run on Phone
```bash
# Use the script (recommended)
scripts\run_phone.bat

# Or manually
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main.dart
```

### Build for Watch
```bash
# Use the script (recommended)
scripts\build_and_install.bat

# Or manually
flutter build apk --debug -t lib/main_wear.dart
```

## 📱 What Each App Shows

### Watch App (main_wear.dart)
```
┌─────────────┐
│   Pulsify   │  ← Round screen
│             │
│    ❤️ 72    │  ← Large BPM
│     BPM     │
│             │
│  [Connect]  │  ← Wear OS buttons
│   [Start]   │
│             │
└─────────────┘
```

### Phone App (main.dart)
```
┌─────────────────────┐
│ Pulsify      [Watch]│  ← Standard app bar
├─────────────────────┤
│  ❤️ Current HR      │
│       72 BPM        │
│    [Light Zone]     │
├─────────────────────┤
│  Avg   Max   Min    │
│  75    85    68     │
├─────────────────────┤
│  ✓ Connected        │
├─────────────────────┤
│  Recent Readings    │
│  • 72 BPM - 2s ago  │
│  • 74 BPM - 5s ago  │
└─────────────────────┘
```

## 🔧 Entry Point Details

### lib/main_wear.dart
```dart
void main() => runApp(const WearApp());

class WearApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WatchShape(  // Wear OS specific
      builder: (context, shape, child) {
        return AmbientMode(  // Battery saving
          builder: (context, mode, child) {
            return MaterialApp(
              home: WearDashboard(),  // Watch UI
            );
          },
        );
      },
    );
  }
}
```

### lib/main.dart
```dart
void main() {
  runApp(const PulsifyPhoneApp());
}

class PulsifyPhoneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,  // Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const PhoneHomePage(),  // Phone UI
    );
  }
}
```

## 🐛 Troubleshooting

### "Phone UI showing on watch"

**Problem**: Running without `-t` flag uses default `main.dart`

**Solution**:
```bash
# Always specify entry point for watch
flutter run -d 6ece264d -t lib/main_wear.dart
```

### "Watch UI showing on phone"

**Problem**: Using wrong entry point

**Solution**:
```bash
# Always specify entry point for phone
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main.dart
```

### "How do I know which is running?"

**Check the UI**:
- **Round screen** = Watch app ✅
- **Rectangular screen** = Phone app ✅

**Check the logs**:
```bash
# Watch logs
adb -s 6ece264d logcat | findstr "WearApp\|WearDashboard"

# Phone logs
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp logcat | findstr "PulsifyPhoneApp\|PhoneHomePage"
```

## 📊 Device Mapping

| Device | Model | ID | Entry Point | UI Type |
|--------|-------|-----|-------------|---------|
| Galaxy Watch | SM_R930 | `adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp` | `lib/main_wear.dart` | Wear OS (round) |
| Android Phone | 22101320G | `6ece264d` | `lib/main.dart` | Material 3 (standard) |

## 🎯 Quick Reference

### Watch Commands (SM_R930)
```bash
# Run
scripts\run_watch.bat
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart

# Build
flutter build apk --debug -t lib/main_wear.dart

# Install
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Phone Commands (22101320G)
```bash
# Run
scripts\run_phone.bat
flutter run -d 6ece264d -t lib/main.dart

# Build
flutter build apk --debug -t lib/main.dart

# Install
adb -s 6ece264d install -r build\app\outputs\flutter-apk\app-debug.apk
```

## ✅ Verification

### After Running on Watch
You should see:
- ✅ Round screen layout
- ✅ Wear OS optimized UI
- ✅ "WearDashboard" in logs
- ✅ Compact buttons and text

### After Running on Phone
You should see:
- ✅ Standard rectangular screen
- ✅ Material 3 design
- ✅ "PhoneHomePage" in logs
- ✅ Large cards and lists

## 🎉 Summary

**Always use the correct entry point**:
- Watch: `-t lib/main_wear.dart`
- Phone: `-t lib/main.dart`

**Use the scripts** (they have the correct flags):
- Watch: `scripts\run_watch.bat`
- Phone: `scripts\run_phone.bat`

**Never run without `-t` flag** on watch, or you'll get the phone UI!

---

**Problem solved!** Now each device gets its own appropriate UI. 🎊
