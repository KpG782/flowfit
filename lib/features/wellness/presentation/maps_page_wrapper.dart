import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/geofence_repository.dart';
import '../services/geofence_service.dart';
import 'maps_page.dart';
import '../services/notification_service.dart';
import '../services/mood_tracker_service.dart';

class MapsPageWrapper extends StatefulWidget {
  const MapsPageWrapper({super.key});
  @override
  State<MapsPageWrapper> createState() => _MapsPageWrapperState();
}

class _MapsPageWrapperState extends State<MapsPageWrapper> {
  late final GeofenceRepository _repo;
  late final GeofenceService _service;
  late final MoodTrackerService _moodTracker;
  StreamSubscription<String>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    _repo = InMemoryGeofenceRepository();
    _service = GeofenceService(repository: _repo);
    _moodTracker = MoodTrackerService(repository: _repo, service: _service);
    // Initialize notifications and start mood tracking (best-effort)
    NotificationService.init();
    _moodTracker.startMonitoring();
    _notificationTapSub = NotificationService.onNotificationTap.listen((payload) {
      if (payload.isEmpty) return;
      if (payload.startsWith('focus:')) {
        final id = payload.replaceFirst('focus:', '');
        _service.requestFocus(id);
      } else if (payload == 'add_sanctuary') {
        _service.requestFocus('add_sanctuary');
      }
    });
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    _moodTracker.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeofenceRepository>.value(value: _repo),
        ChangeNotifierProvider<GeofenceService>.value(value: _service),
        Provider<MoodTrackerService>.value(value: _moodTracker),
      ],
      child: const WellnessMapsPage(),
    );
  }
}

// How to use:
// - Add `MapsPageWrapper()` to your application's routing for `wellness` category.
// - This feature uses `flutter_map` + OpenStreetMap tiles by default — no API keys required.
// - Optionally, replace `InMemoryGeofenceRepository` with a persisted implementation.
