@echo off
echo ========================================
echo FlowFit - Run on Galaxy Watch
echo ========================================
echo.
echo Device: SM_R930 (adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp)
echo Entry: lib/main_wear.dart
echo.
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart
