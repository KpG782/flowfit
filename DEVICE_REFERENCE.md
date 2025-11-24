# Device Reference Card

## 📱 Connected Devices

### Galaxy Watch (SM_R930) ⌚
- **Device ID**: `adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`
- **Model**: SM_R930
- **Type**: Wear OS Smartwatch
- **Entry Point**: `lib/main_wear.dart`
- **UI**: Wear OS (round screen, compact)

**Run Command**:
```bash
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart
```

**Quick Script**:
```bash
scripts\run_watch.bat
```

---

### Android Phone (22101320G) 📱
- **Device ID**: `6ece264d`
- **Model**: 22101320G
- **Type**: Android Phone
- **Entry Point**: `lib/main.dart`
- **UI**: Material 3 (standard screen)

**Run Command**:
```bash
flutter run -d 6ece264d -t lib/main.dart
```

**Quick Script**:
```bash
scripts\run_phone.bat
```

---

## 🎯 Quick Reference

| What | Device | Command |
|------|--------|---------|
| **Watch App** | SM_R930 | `scripts\run_watch.bat` |
| **Phone App** | 22101320G | `scripts\run_phone.bat` |
| **Build Watch** | SM_R930 | `scripts\build_and_install.bat` |

## 🔍 How to Check Devices

```bash
adb devices -l
```

**Output**:
```
6ece264d               device product:redwood_global model:22101320G device:redwood
adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp device product:fresh6bsue model:SM_R930 device:fresh6bs
```

## ⚠️ Important Notes

1. **SM_R930** = Galaxy Watch (the long device ID)
2. **22101320G** = Android Phone (the short device ID)
3. **Always use `-t lib/main_wear.dart`** for watch
4. **Always use `-t lib/main.dart`** for phone

## 🚀 Most Common Commands

### Run Watch App
```bash
scripts\run_watch.bat
```

### Run Phone App
```bash
scripts\run_phone.bat
```

### View Watch Logs
```bash
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp logcat | findstr "FlowFit"
```

### View Phone Logs
```bash
adb -s 6ece264d logcat | findstr "FlowFit"
```

---

**Keep this file handy for quick device reference!** 📌
