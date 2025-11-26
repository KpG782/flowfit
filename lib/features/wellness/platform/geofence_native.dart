import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'native_geofence_wrapper.dart' as ngw; // wrapper for native_geofence plugin

class GeofenceNative {
  static const MethodChannel _channel = MethodChannel('com.flowfit.geofence/native');
  static const EventChannel _events = EventChannel('com.flowfit.geofence/events');

  static Future<bool> register(GeofenceMission mission) async {
    try {
      // Prefer native_geofence plugin if available
      try {
        final ok = await ngw.NativeGeofenceWrapper.register(mission);
        if (ok) return true;
      } catch (_) {}

      // Fallback to method-channel-based registration for custom native implementation
      await _channel.invokeMethod('registerGeofence', {
        'id': mission.id,
        'lat': mission.center.latitude,
        'lon': mission.center.longitude,
        'radius': mission.radiusMeters,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unregister(String id) async {
    try {
      try {
        final ok = await ngw.NativeGeofenceWrapper.unregister(id);
        if (ok) return true;
      } catch (_) {}

      await _channel.invokeMethod('unregisterGeofence', {'id': id});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Stream<dynamic> get events => _events.receiveBroadcastStream();
  static Stream<Map<String, dynamic>> get nativeGeofenceEvents => ngw.NativeGeofenceWrapper.events;
}
