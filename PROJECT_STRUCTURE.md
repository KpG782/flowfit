# FlowFit Project Structure

Clean and organized project structure for the FlowFit health and fitness tracking application.

## 📁 Root Directory

```
flowfit/
├── android/              # Android native code
├── ios/                  # iOS native code (future)
├── lib/                  # Flutter/Dart source code
├── docs/                 # 📚 All documentation
├── scripts/              # 🔧 Build and run scripts
├── test/                 # Unit and widget tests
├── .kiro/                # Kiro IDE configuration
├── pubspec.yaml          # Flutter dependencies
└── README.md             # Main project documentation
```

## 📚 Documentation (`docs/`)

All project documentation is organized in the `docs/` folder:

### Quick Start & Setup
- `QUICK_START.md` - 5-minute quick start guide
- `SAMSUNG_HEALTH_SETUP_GUIDE.md` - Complete Samsung Health integration
- `IMPLEMENTATION_CHECKLIST.md` - Step-by-step testing guide

### Troubleshooting
- `INSTALLATION_TROUBLESHOOTING.md` - Installation issues and solutions
- `BUILD_FIXES_APPLIED.md` - Recent build fixes and changes

### Architecture
- `HEART_RATE_DATA_FLOW.md` - Data flow architecture
- `WEAR_OS_SETUP.md` - Wear OS development setup
- `RUN_INSTRUCTIONS.md` - Device-specific run commands

### Improvements
- `VGV_IMPROVEMENTS.md` - VGV best practices applied
- `WEAR_OS_IMPROVEMENTS.md` - Wear OS optimizations
- `SAMSUNG_HEALTH_IMPLEMENTATION_SUMMARY.md` - Implementation summary

**See [docs/README.md](docs/README.md) for complete documentation index.**

## 🔧 Scripts (`scripts/`)

Build and deployment automation scripts:

- `build_and_install.bat` - Automated build and install on watch
- `run_watch.bat` - Quick run on Galaxy Watch (6ece264d)
- `run_phone.bat` - Quick run on Android Phone

**See [scripts/README.md](scripts/README.md) for usage instructions.**

## 📱 Source Code (`lib/`)

```
lib/
├── main.dart                 # Phone app entry point
├── main_wear.dart            # Watch app entry point
├── models/                   # Data models
│   ├── heart_rate_data.dart
│   ├── activity.dart
│   ├── sleep_session.dart
│   └── mood_log.dart
├── services/                 # Business logic
│   ├── watch_bridge.dart     # Samsung Health SDK bridge
│   ├── supabase_service.dart # Backend service
│   └── sleep_service.dart
├── screens/                  # UI screens
│   ├── wear/                 # Watch-specific screens
│   │   ├── wear_dashboard.dart
│   │   └── relax_screen.dart
│   ├── workout/              # Workout screens
│   │   ├── activity_tracker.dart
│   │   └── workout_library.dart
│   ├── sleep/                # Sleep tracking
│   │   └── sleep_mode.dart
│   └── nutrition/            # Nutrition logging
│       └── food_logger.dart
└── examples/                 # Example implementations
    └── heart_rate_example.dart
```

## 🤖 Android Native (`android/`)

```
android/
├── app/
│   ├── src/main/
│   │   ├── kotlin/com/example/flowfit/
│   │   │   ├── MainActivity.kt           # Main activity
│   │   │   └── HealthTrackingManager.kt  # Samsung Health SDK manager
│   │   └── AndroidManifest.xml           # App manifest
│   ├── libs/
│   │   └── samsung-health-sensor-api-1.4.1.aar  # Samsung Health SDK
│   └── build.gradle.kts                  # App-level Gradle config
└── build.gradle.kts                      # Project-level Gradle config
```

## 🎯 Quick Navigation

### I want to...

**Build and install the app**
```bash
scripts\build_and_install.bat
```

**Run on watch**
```bash
scripts\run_watch.bat
```

**Run on phone**
```bash
scripts\run_phone.bat
```

**Read documentation**
- Start with [README.md](README.md)
- Then see [docs/README.md](docs/README.md)

**Fix installation issues**
- See [docs/INSTALLATION_TROUBLESHOOTING.md](docs/INSTALLATION_TROUBLESHOOTING.md)

**Understand the architecture**
- See [docs/HEART_RATE_DATA_FLOW.md](docs/HEART_RATE_DATA_FLOW.md)

## 📝 File Organization Rules

### Documentation
- ✅ All `.md` files (except README.md) go in `docs/`
- ✅ Keep docs organized by category
- ✅ Update `docs/README.md` when adding new docs

### Scripts
- ✅ All `.bat` files go in `scripts/`
- ✅ Keep scripts simple and well-commented
- ✅ Update `scripts/README.md` when adding new scripts

### Source Code
- ✅ Follow Flutter project structure
- ✅ Group by feature (models, services, screens)
- ✅ Keep examples in `lib/examples/`

### Build Artifacts
- ❌ Never commit `build/` folder
- ❌ Never commit `.dart_tool/`
- ❌ Never commit `*.log` files
- ✅ Use `.gitignore` to exclude these

## 🧹 Keeping It Clean

### Regular Maintenance

```bash
# Clean build artifacts
flutter clean

# Remove temporary files
del nul
del *.log

# Update dependencies
flutter pub get
flutter pub upgrade
```

### Before Committing

1. ✅ Run `flutter analyze`
2. ✅ Run tests: `flutter test`
3. ✅ Check `.gitignore` is up to date
4. ✅ Update documentation if needed
5. ✅ Remove debug logs and comments

## 📊 Project Statistics

### Lines of Code (Approximate)
- Dart: ~5,000 lines
- Kotlin: ~500 lines
- Documentation: ~3,000 lines

### File Count
- Dart files: ~30
- Kotlin files: 2
- Documentation files: 11
- Scripts: 3

### Supported Platforms
- ✅ Wear OS (Galaxy Watch4+)
- ✅ Android Phone
- ⏳ iOS (future)

## 🔗 Related Files

- [README.md](README.md) - Main project documentation
- [docs/README.md](docs/README.md) - Documentation index
- [scripts/README.md](scripts/README.md) - Scripts documentation
- [pubspec.yaml](pubspec.yaml) - Flutter dependencies

## 💡 Tips

- **Keep documentation up to date** - Update docs when code changes
- **Use scripts for common tasks** - Saves time and reduces errors
- **Follow the structure** - Makes the project easier to navigate
- **Clean regularly** - Remove unused files and artifacts

---

**Last Updated**: 2025-01-XX

For questions about project structure, see the documentation or open an issue.
