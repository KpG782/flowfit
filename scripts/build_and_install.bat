@echo off
echo ========================================
echo FlowFit Build and Install Script
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Step 3: Building APK for watch...
echo Using entry point: lib/main_wear.dart
flutter build apk --debug -t lib/main_wear.dart
if %errorlevel% neq 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo Step 4: Checking connected devices...
adb devices

echo.
echo Step 5: Installing on watch (SM_R930)...
echo Please approve the installation on your watch when prompted!
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp install -r build\app\outputs\flutter-apk\app-debug.apk
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installation failed
    echo.
    echo Common issues:
    echo 1. Watch not connected - Check 'adb devices'
    echo 2. Installation blocked - Approve on watch screen
    echo 3. Missing library - Check AndroidManifest.xml
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! App installed on watch
echo ========================================
echo.
echo To run the app:
echo   flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart
echo.
echo To view logs:
echo   adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp logcat ^| findstr "FlowFit MainActivity HealthTrackingManager"
echo.
pause
