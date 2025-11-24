import 'dart:async';
import 'package:flutter/services.dart';
import '../models/heart_rate_data.dart';
import 'package:logger/logger.dart';

/// Service for receiving heart rate data from Galaxy Watch
/// Uses Wearable Data Layer API to listen for messages from watch
class PhoneDataListener {
  static const MethodChannel _methodChannel =
      MethodChannel('com.flowfit.phone/data');
  static const EventChannel _heartRateEventChannel =
      EventChannel('com.flowfit.phone/heartrate');

  final Logger _logger = Logger();

  Stream<HeartRateData>? _heartRateStream;
  StreamController<HeartRateData>? _heartRateController;

  /// Get stream of heart rate data from watch
  Stream<HeartRateData> get heartRateStream {
    _heartRateStream ??= _heartRateEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
      try {
        final jsonMap = Map<String, dynamic>.from(event as Map);
        final heartRateData = HeartRateData.fromJson(jsonMap);
        _logger.d('Received heart rate from watch: ${heartRateData.bpm} bpm');
        return heartRateData;
      } catch (e, stackTrace) {
        _logger.e('Failed to parse heart rate data', error: e, stackTrace: stackTrace);
        rethrow;
      }
    }).handleError((error, stackTrace) {
      _logger.e('Error in heart rate stream', error: error, stackTrace: stackTrace);
    });

    return _heartRateStream!;
  }

  /// Start listening for data from watch
  Future<bool> startListening() async {
    try {
      _logger.i('Starting to listen for watch data');
      final result = await _methodChannel.invokeMethod<bool>('startListening');
      _logger.i('Listening started: ${result ?? false}');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('Failed to start listening', error: e);
      return false;
    }
  }

  /// Stop listening for data from watch
  Future<void> stopListening() async {
    try {
      _logger.i('Stopping listening for watch data');
      await _methodChannel.invokeMethod<void>('stopListening');
    } on PlatformException catch (e) {
      _logger.e('Failed to stop listening', error: e);
    }
  }

  /// Check if watch is connected
  Future<bool> isWatchConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isWatchConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('Failed to check watch connection', error: e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _heartRateController?.close();
    _heartRateController = null;
    _heartRateStream = null;
  }
}
