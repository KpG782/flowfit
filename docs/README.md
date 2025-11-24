# FlowFit Documentation

Complete documentation for the FlowFit health and fitness tracking application.

## 📖 Table of Contents

### Getting Started

1. **[QUICK_START.md](QUICK_START.md)** - 5-minute quick start guide
   - Prerequisites
   - Installation steps
   - First run
   - Basic usage

2. **[SAMSUNG_HEALTH_SETUP_GUIDE.md](SAMSUNG_HEALTH_SETUP_GUIDE.md)** - Complete Samsung Health integration
   - Hardware requirements
   - Software setup
   - Architecture overview
   - API usage examples
   - Troubleshooting

3. **[IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)** - Step-by-step testing
   - Pre-testing checklist
   - Testing procedures
   - Integration points
   - Data analysis examples

### Troubleshooting

4. **[INSTALLATION_TROUBLESHOOTING.md](INSTALLATION_TROUBLESHOOTING.md)** - Installation issues
   - Common errors and solutions
   - Installation methods
   - Pre-installation checklist
   - Verification steps
   - Watch-specific settings

5. **[BUILD_FIXES_APPLIED.md](BUILD_FIXES_APPLIED.md)** - Recent build fixes
   - ConnectionListener API fix
   - Wearable library fix
   - Code changes summary
   - Testing instructions

### Architecture & Development

6. **[HEART_RATE_DATA_FLOW.md](HEART_RATE_DATA_FLOW.md)** - Data flow architecture
   - System architecture
   - Data flow diagrams
   - Component interactions
   - API documentation

7. **[WEAR_OS_SETUP.md](WEAR_OS_SETUP.md)** - Wear OS development setup
   - Development environment
   - Device configuration
   - Debugging setup
   - Best practices

8. **[RUN_INSTRUCTIONS.md](RUN_INSTRUCTIONS.md)** - Device-specific commands
   - Watch commands
   - Phone commands
   - Build commands
   - Deployment instructions

### Improvements & Notes

9. **[VGV_IMPROVEMENTS.md](VGV_IMPROVEMENTS.md)** - VGV best practices
   - Code quality improvements
   - Architecture patterns
   - Performance optimizations
   - Testing strategies

10. **[WEAR_OS_IMPROVEMENTS.md](WEAR_OS_IMPROVEMENTS.md)** - Wear OS optimizations
    - UI/UX improvements
    - Battery optimization
    - Performance tuning
    - Accessibility features

11. **[SAMSUNG_HEALTH_IMPLEMENTATION_SUMMARY.md](SAMSUNG_HEALTH_IMPLEMENTATION_SUMMARY.md)** - Implementation summary
    - What was implemented
    - Key differences from tutorial
    - Usage examples
    - Next steps

## 🎯 Quick Navigation

### I want to...

**Get started quickly**
→ [QUICK_START.md](QUICK_START.md)

**Set up Samsung Health integration**
→ [SAMSUNG_HEALTH_SETUP_GUIDE.md](SAMSUNG_HEALTH_SETUP_GUIDE.md)

**Fix installation errors**
→ [INSTALLATION_TROUBLESHOOTING.md](INSTALLATION_TROUBLESHOOTING.md)

**Understand the architecture**
→ [HEART_RATE_DATA_FLOW.md](HEART_RATE_DATA_FLOW.md)

**See what was recently fixed**
→ [BUILD_FIXES_APPLIED.md](BUILD_FIXES_APPLIED.md)

**Run on specific devices**
→ [RUN_INSTRUCTIONS.md](RUN_INSTRUCTIONS.md)

**Test the implementation**
→ [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)

## 📱 Device Information

### Watch (Primary Device)
- **Device ID**: `6ece264d`
- **Model**: Galaxy Watch (22101320G)
- **Platform**: Wear OS powered by Samsung
- **Run Command**: `flutter run -d 6ece264d`

### Phone (Companion Device)
- **Device ID**: `adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`
- **Platform**: Android
- **Run Command**: `flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`

## 🔧 Common Commands

### Build & Run
```bash
# Watch
flutter run -d 6ece264d

# Phone
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp

# Build APK
flutter build apk --debug
```

### Installation
```bash
# Install on watch
adb -s 6ece264d install -r build\app\outputs\flutter-apk\app-debug.apk

# Uninstall
adb -s 6ece264d uninstall com.example.flowfit
```

### Debugging
```bash
# View logs
adb -s 6ece264d logcat | findstr "FlowFit MainActivity HealthTrackingManager"

# Check devices
adb devices

# Check installed packages
adb -s 6ece264d shell pm list packages | findstr flowfit
```

## 📚 Additional Resources

### External Documentation
- [Samsung Health Sensor SDK](https://developer.samsung.com/health/android/data/guide/health-sensor.html)
- [Flutter Wear OS](https://docs.flutter.dev/deployment/wear)
- [Supabase Documentation](https://supabase.com/docs)

### Code Examples
- `lib/examples/heart_rate_example.dart` - Complete heart rate tracking example
- See individual documentation files for more code snippets

## 🆘 Getting Help

1. **Check the relevant documentation** above
2. **Review troubleshooting guides**
3. **Check logcat output** for errors
4. **Verify device compatibility**
5. **Open an issue** on GitHub

## 📝 Documentation Updates

Last updated: 2025-01-XX

All documentation is kept in sync with the codebase. If you find outdated information, please report it.

---

**Back to [Main README](../README.md)**
