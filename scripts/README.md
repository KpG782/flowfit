# FlowFit Build Scripts

Automated scripts for building and running FlowFit on different devices.

## 📜 Available Scripts

### 1. build_and_install.bat
**Purpose**: Automated build and installation on Galaxy Watch

**Usage**:
```bash
scripts\build_and_install.bat
```

**What it does**:
1. Cleans previous builds (`flutter clean`)
2. Gets dependencies (`flutter pub get`)
3. Builds debug APK (`flutter build apk --debug`)
4. Checks connected devices (`adb devices`)
5. Installs on watch (`adb -s 6ece264d install`)

**Requirements**:
- Watch connected and visible in `adb devices`
- Developer mode enabled on watch
- ADB debugging enabled on watch

**Important**: You must approve the installation on your watch screen when prompted!

---

### 2. run_watch.bat
**Purpose**: Quick run on Galaxy Watch

**Usage**:
```bash
scripts\run_watch.bat
```

**What it does**:
- Runs `flutter run -d 6ece264d`
- Launches app on watch in debug mode
- Enables hot reload

**Requirements**:
- Watch connected
- Previous build successful

---

### 3. run_phone.bat
**Purpose**: Quick run on Android Phone

**Usage**:
```bash
scripts\run_phone.bat
```

**What it does**:
- Runs `flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`
- Launches companion app on phone
- Enables hot reload

**Requirements**:
- Phone connected
- Previous build successful

---

## 🚀 Quick Start

### First Time Setup

1. **Connect your devices**:
   ```bash
   adb devices
   ```
   Should show:
   ```
   6ece264d        device
   adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp    device
   ```

2. **Build and install on watch**:
   ```bash
   scripts\build_and_install.bat
   ```

3. **Approve installation on watch** when prompted

4. **Run on watch**:
   ```bash
   scripts\run_watch.bat
   ```

### Daily Development

For quick iterations during development:

```bash
# Make code changes, then:
scripts\run_watch.bat

# Or for phone:
scripts\run_phone.bat
```

Hot reload will work automatically for quick UI changes.

---

## 🔧 Manual Commands

If you prefer manual control:

### Watch Commands
```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --debug

# Install
adb -s 6ece264d install -r build\app\outputs\flutter-apk\app-debug.apk

# Run with hot reload
flutter run -d 6ece264d

# Uninstall
adb -s 6ece264d uninstall com.example.flowfit
```

### Phone Commands
```bash
# Run on phone
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp

# Install APK
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp install -r build\app\outputs\flutter-apk\app-debug.apk
```

---

## 🐛 Troubleshooting

### Script Fails with "Device not found"

**Check devices**:
```bash
adb devices
```

**If watch not showing**:
1. Check USB connection
2. Enable ADB debugging on watch
3. Restart ADB: `adb kill-server && adb start-server`

### "INSTALL_FAILED_USER_RESTRICTED"

**Solution**: Approve installation on watch screen
- Watch will show "Install app?" prompt
- Tap "Install" button
- Must approve within 30 seconds

### "INSTALL_FAILED_MISSING_SHARED_LIBRARY"

**Solution**: This should be fixed in the latest build
- Check `android/app/src/main/AndroidManifest.xml`
- Ensure wearable library is set to `required="false"`

### Build Fails

**Clean and rebuild**:
```bash
flutter clean
flutter pub get
scripts\build_and_install.bat
```

**Check Kotlin errors**:
- Review `android/app/src/main/kotlin/` files
- Check logcat for detailed errors

---

## 📊 Script Output

### Successful Build
```
========================================
FlowFit Build and Install Script
========================================

Step 1: Cleaning previous builds...
✓ Clean complete

Step 2: Getting dependencies...
✓ Dependencies resolved

Step 3: Building APK for watch...
✓ Built build\app\outputs\flutter-apk\app-debug.apk

Step 4: Checking connected devices...
6ece264d        device

Step 5: Installing on watch (6ece264d)...
✓ Installation successful

========================================
SUCCESS! App installed on watch
========================================
```

### Failed Build
```
ERROR: Build failed
Compilation error. See log for more details

Common issues:
1. Kotlin compilation errors
2. Missing dependencies
3. SDK version mismatch
```

---

## 🎯 Best Practices

### Development Workflow

1. **Use `run_watch.bat` for quick iterations**
   - Faster than full rebuild
   - Hot reload enabled
   - Good for UI changes

2. **Use `build_and_install.bat` for clean builds**
   - After major changes
   - After dependency updates
   - When debugging build issues

3. **Check logs regularly**
   ```bash
   adb -s 6ece264d logcat | findstr "FlowFit"
   ```

### Performance Tips

- **Keep watch connected via USB** for faster deployment
- **Use hot reload** (`r` in terminal) for quick UI changes
- **Use hot restart** (`R` in terminal) for state changes
- **Clean build** only when necessary (it's slow)

---

## 📝 Creating Custom Scripts

You can create your own scripts based on these templates:

### Example: Clean Install Script
```batch
@echo off
echo Cleaning and reinstalling...
flutter clean
adb -s 6ece264d uninstall com.example.flowfit
flutter pub get
flutter run -d 6ece264d
```

### Example: Log Viewer Script
```batch
@echo off
echo Viewing FlowFit logs...
adb -s 6ece264d logcat | findstr "FlowFit MainActivity HealthTrackingManager"
```

---

## 🔗 Related Documentation

- **[Installation Troubleshooting](../docs/INSTALLATION_TROUBLESHOOTING.md)** - Detailed error solutions
- **[Build Fixes Applied](../docs/BUILD_FIXES_APPLIED.md)** - Recent fixes
- **[Run Instructions](../docs/RUN_INSTRUCTIONS.md)** - Device-specific commands

---

## 💡 Tips

- **Always approve installations on watch** - Required for security
- **Keep watch unlocked during install** - Installation fails if locked
- **Check battery level** - Low battery can cause issues
- **Use WiFi debugging** - For wireless development (advanced)

---

**Back to [Main README](../README.md)**
