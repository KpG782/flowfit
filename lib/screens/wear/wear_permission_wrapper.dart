import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// dart:io is not required in this wrapper — removed unused import

/// Permission wrapper for Wear OS screens
/// Ensures BODY_SENSORS or health.READ_HEART_RATE permission is granted
/// before showing the main content
class WearPermissionWrapper extends StatefulWidget {
  final Widget child;
  
  const WearPermissionWrapper({
    super.key,
    required this.child,
  });

  @override
  State<WearPermissionWrapper> createState() => _WearPermissionWrapperState();
}

class _WearPermissionWrapperState extends State<WearPermissionWrapper>
    with WidgetsBindingObserver {
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAndRequestPermission();
    }
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Check current permission status
      var status = await Permission.sensors.status;
      
      if (!status.isGranted) {
        // Request permission
        status = await Permission.sensors.request();
      }

      setState(() {
        _permissionStatus = status;
        _isChecking = false;
      });
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() {
        _permissionStatus = PermissionStatus.denied;
        _isChecking = false;
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    // Re-check after returning from settings
    await Future.delayed(const Duration(milliseconds: 500));
    _checkAndRequestPermission();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking permissions...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_permissionStatus.isGranted) {
      // Permission granted - show main content
      return widget.child;
    }

    // Permission denied - show rationale
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sensors_off,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _permissionStatus.isPermanentlyDenied
                    ? 'Permission Permanently Denied'
                    : 'Body Sensors Permission Required',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _permissionStatus.isPermanentlyDenied
                    ? 'Please enable body sensors permission in Settings to use heart rate monitoring.'
                    : 'This app needs access to body sensors to monitor your heart rate.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_permissionStatus.isPermanentlyDenied)
                ElevatedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Open Settings'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _checkAndRequestPermission,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Grant Permission'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
