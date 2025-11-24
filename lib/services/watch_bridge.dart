import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:logger/logger.dart';
import '../models/heart_rate_data.dart';
import '../models/permission_status.dart';
import '../models/sensor_error.dart';
import '../models/sensor_error_code.dart';

/// Service for managing communication with Samsung Health Sensor API
/// via native Android code through Method Channel
class WatchBridgeService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.flowfit.watch/data');
  static const EventChannel _heartRateEventChannel =
      EventChannel('com.flowfit.watch/heartrate');

  // Logger instance for debugging
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);
  static const Duration _operationTimeout = Duration(seconds: 10);

  Stream<HeartRateData>? _heartRateStream;
  StreamSubscription<HeartRateData>? _heartRateSubscription;
  
  // Permission state stream
  final StreamController<PermissionStatus> _permissionStateController =
      StreamController<PermissionStatus>.broadcast();
  Timer? _permissionCheckTimer;

  /// Request BODY_SENSORS permission from the user
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestBodySensorPermission() async {
    _logger.i('Requesting body sensor permission');
    
    try {
      final status = await ph.Permission.sensors.request()
          .timeout(_operationTimeout);
      
      _logger.d('Permission request result: ${status.isGranted}');
      
      // Emit permission state change
      await _updatePermissionState();
      return status.isGranted;
    } on TimeoutException catch (e) {
      _logger.e('Permission request timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Permission request timed out',
        details: e.toString(),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to request body sensor permission', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.permissionDenied,
        message: 'Failed to request body sensor permission',
        details: e.toString(),
      );
    }
  }

  /// Check the current BODY_SENSORS permission status
  /// Returns the current permission state without requesting
  Future<PermissionStatus> checkBodySensorPermission() async {
    _logger.d('Checking body sensor permission status');
    
    try {
      final status = await ph.Permission.sensors.status
          .timeout(_operationTimeout);
      
      PermissionStatus result;
      if (status.isGranted) {
        result = PermissionStatus.granted;
      } else if (status.isDenied || status.isPermanentlyDenied) {
        result = PermissionStatus.denied;
      } else {
        result = PermissionStatus.notDetermined;
      }
      
      _logger.d('Permission status: $result');
      return result;
    } on TimeoutException catch (e) {
      _logger.e('Permission check timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Permission check timed out',
        details: e.toString(),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to check body sensor permission', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Failed to check body sensor permission',
        details: e.toString(),
      );
    }
  }

  /// Connect to Samsung Health services on the watch
  /// Returns true if connection is successful, false otherwise
  /// Implements retry logic with exponential backoff
  Future<bool> connectToWatch() async {
    _logger.i('Attempting to connect to watch');
    
    return await _retryWithExponentialBackoff<bool>(
      operation: () async {
        try {
          final result = await _methodChannel
              .invokeMethod<bool>('connectWatch')
              .timeout(_operationTimeout);
          
          final connected = result ?? false;
          _logger.i('Watch connection result: $connected');
          return connected;
        } on TimeoutException catch (e) {
          _logger.w('Watch connection timed out', error: e);
          throw SensorError(
            code: SensorErrorCode.timeout,
            message: 'Watch connection timed out',
            details: e.toString(),
          );
        } on PlatformException catch (e) {
          _logger.e('Platform exception during watch connection', error: e);
          throw _mapPlatformException(e, 'Failed to connect to watch');
        }
      },
      operationName: 'connectToWatch',
    );
  }

  /// Disconnect from Samsung Health services
  Future<void> disconnectFromWatch() async {
    _logger.i('Disconnecting from watch');
    
    try {
      await _methodChannel
          .invokeMethod<void>('disconnectWatch')
          .timeout(_operationTimeout);
      
      _logger.i('Successfully disconnected from watch');
    } on TimeoutException catch (e) {
      _logger.e('Disconnect timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Disconnect operation timed out',
        details: e.toString(),
      );
    } on PlatformException catch (e) {
      _logger.e('Platform exception during disconnect', error: e);
      throw _mapPlatformException(e, 'Failed to disconnect from watch');
    } catch (e, stackTrace) {
      _logger.e('Failed to disconnect from watch', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Failed to disconnect from watch',
        details: e.toString(),
      );
    }
  }

  /// Check if the watch is currently connected
  /// Returns true if connected, false otherwise
  Future<bool> isWatchConnected() async {
    _logger.d('Checking watch connection status');
    
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('isWatchConnected')
          .timeout(_operationTimeout);
      
      final connected = result ?? false;
      _logger.d('Watch connected: $connected');
      return connected;
    } on TimeoutException catch (e) {
      _logger.e('Connection status check timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Connection status check timed out',
        details: e.toString(),
      );
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking connection status', error: e);
      throw _mapPlatformException(e, 'Failed to check watch connection status');
    } catch (e, stackTrace) {
      _logger.e('Failed to check watch connection status', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Failed to check watch connection status',
        details: e.toString(),
      );
    }
  }

  /// Start heart rate tracking
  /// Returns true if tracking started successfully, false otherwise
  Future<bool> startHeartRateTracking() async {
    _logger.i('Starting heart rate tracking');
    
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('startHeartRate')
          .timeout(_operationTimeout);
      
      final started = result ?? false;
      _logger.i('Heart rate tracking started: $started');
      return started;
    } on TimeoutException catch (e) {
      _logger.e('Start heart rate tracking timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Start heart rate tracking timed out',
        details: e.toString(),
      );
    } on PlatformException catch (e) {
      _logger.e('Platform exception starting heart rate tracking', error: e);
      throw _mapPlatformException(e, 'Failed to start heart rate tracking');
    } catch (e, stackTrace) {
      _logger.e('Failed to start heart rate tracking', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.sensorUnavailable,
        message: 'Failed to start heart rate tracking',
        details: e.toString(),
      );
    }
  }

  /// Stop heart rate tracking
  Future<void> stopHeartRateTracking() async {
    _logger.i('Stopping heart rate tracking');
    
    try {
      await _methodChannel
          .invokeMethod<void>('stopHeartRate')
          .timeout(_operationTimeout);
      
      _logger.i('Heart rate tracking stopped successfully');
    } on TimeoutException catch (e) {
      _logger.e('Stop heart rate tracking timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Stop heart rate tracking timed out',
        details: e.toString(),
      );
    } on PlatformException catch (e) {
      _logger.e('Platform exception stopping heart rate tracking', error: e);
      throw _mapPlatformException(e, 'Failed to stop heart rate tracking');
    } catch (e, stackTrace) {
      _logger.e('Failed to stop heart rate tracking', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Failed to stop heart rate tracking',
        details: e.toString(),
      );
    }
  }

  /// Get the current heart rate reading
  /// Returns HeartRateData if available, null otherwise
  Future<HeartRateData?> getCurrentHeartRate() async {
    _logger.d('Getting current heart rate');
    
    try {
      final result = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('getCurrentHeartRate')
          .timeout(_operationTimeout);
      
      if (result == null) {
        _logger.d('No heart rate data available');
        return null;
      }

      // Convert dynamic map to Map<String, dynamic>
      final jsonMap = Map<String, dynamic>.from(result);
      final heartRateData = HeartRateData.fromJson(jsonMap);
      _logger.d('Current heart rate: ${heartRateData.bpm} bpm');
      return heartRateData;
    } on TimeoutException catch (e) {
      _logger.e('Get current heart rate timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Get current heart rate timed out',
        details: e.toString(),
      );
    } on PlatformException catch (e) {
      _logger.e('Platform exception getting current heart rate', error: e);
      throw _mapPlatformException(e, 'Failed to get current heart rate');
    } catch (e, stackTrace) {
      _logger.e('Failed to get current heart rate', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Failed to get current heart rate',
        details: e.toString(),
      );
    }
  }

  /// Get a stream of heart rate data updates
  /// Returns a Stream that emits HeartRateData as new readings arrive
  Stream<HeartRateData> get heartRateStream {
    _heartRateStream ??= _heartRateEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
      try {
        final jsonMap = Map<String, dynamic>.from(event as Map);
        final heartRateData = HeartRateData.fromJson(jsonMap);
        _logger.d('Heart rate stream data: ${heartRateData.bpm} bpm');
        return heartRateData;
      } catch (e, stackTrace) {
        _logger.e('Failed to parse heart rate data', error: e, stackTrace: stackTrace);
        throw SensorError(
          code: SensorErrorCode.unknown,
          message: 'Failed to parse heart rate data',
          details: e.toString(),
        );
      }
    }).handleError((error, stackTrace) {
      _logger.e('Error in heart rate stream', error: error, stackTrace: stackTrace);
      if (error is PlatformException) {
        throw _mapPlatformException(error, 'Heart rate stream error');
      }
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Heart rate stream error',
        details: error.toString(),
      );
    });

    return _heartRateStream!;
  }

  /// Get a stream of permission state changes
  /// Returns a Stream that emits PermissionStatus when permission state changes
  Stream<PermissionStatus> get permissionStateStream =>
      _permissionStateController.stream;

  /// Start monitoring permission state changes
  /// Checks permission status periodically and emits changes
  void startPermissionMonitoring({Duration interval = const Duration(seconds: 2)}) {
    // Stop any existing timer
    _permissionCheckTimer?.cancel();
    
    // Emit initial state
    _updatePermissionState();
    
    // Set up periodic checks
    _permissionCheckTimer = Timer.periodic(interval, (_) {
      _updatePermissionState();
    });
  }

  /// Stop monitoring permission state changes
  void stopPermissionMonitoring() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
  }

  /// Update and emit current permission state
  Future<void> _updatePermissionState() async {
    try {
      final status = await checkBodySensorPermission();
      if (!_permissionStateController.isClosed) {
        _permissionStateController.add(status);
      }
    } catch (e, stackTrace) {
      // Silently handle errors in background monitoring
      _logger.w('Error checking permission state', error: e, stackTrace: stackTrace);
    }
  }

  /// Open app settings for permission management
  /// Returns true if settings were opened successfully
  Future<bool> openAppSettings() async {
    _logger.i('Opening app settings');
    
    try {
      final result = await ph.openAppSettings()
          .timeout(_operationTimeout);
      
      _logger.i('App settings opened: $result');
      return result;
    } on TimeoutException catch (e) {
      _logger.e('Open app settings timed out', error: e);
      throw SensorError(
        code: SensorErrorCode.timeout,
        message: 'Open app settings timed out',
        details: e.toString(),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to open app settings', error: e, stackTrace: stackTrace);
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Failed to open app settings',
        details: e.toString(),
      );
    }
  }

  /// Retry an operation with exponential backoff
  /// Used for connection operations that may fail temporarily
  Future<T> _retryWithExponentialBackoff<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = _maxRetries,
    Duration initialDelay = _initialRetryDelay,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        // Check if we should retry
        final shouldRetry = attempt < maxRetries && _isRetryableError(e);
        
        if (!shouldRetry) {
          _logger.e('$operationName failed after $attempt attempts', error: e);
          rethrow;
        }

        _logger.w(
          '$operationName failed (attempt $attempt/$maxRetries), '
          'retrying in ${delay.inMilliseconds}ms',
          error: e,
        );

        // Wait before retrying
        await Future.delayed(delay);
        
        // Exponential backoff: double the delay for next attempt
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }
  }

  /// Check if an error is retryable
  bool _isRetryableError(dynamic error) {
    if (error is SensorError) {
      // Retry on connection failures, timeouts, and service unavailable
      return error.code == SensorErrorCode.connectionFailed ||
          error.code == SensorErrorCode.timeout ||
          error.code == SensorErrorCode.serviceUnavailable;
    }
    
    if (error is PlatformException) {
      // Retry on specific platform error codes
      return error.code == 'CONNECTION_FAILED' ||
          error.code == 'TIMEOUT' ||
          error.code == 'SERVICE_UNAVAILABLE';
    }
    
    // Don't retry on other errors
    return false;
  }

  /// Map PlatformException to SensorError with appropriate error code
  SensorError _mapPlatformException(PlatformException e, String message) {
    SensorErrorCode code;
    
    switch (e.code) {
      case 'PERMISSION_DENIED':
        code = SensorErrorCode.permissionDenied;
        break;
      case 'SERVICE_UNAVAILABLE':
        code = SensorErrorCode.serviceUnavailable;
        break;
      case 'CONNECTION_FAILED':
        code = SensorErrorCode.connectionFailed;
        break;
      case 'SENSOR_NOT_SUPPORTED':
        code = SensorErrorCode.sensorNotSupported;
        break;
      case 'SENSOR_UNAVAILABLE':
        code = SensorErrorCode.sensorUnavailable;
        break;
      case 'TIMEOUT':
        code = SensorErrorCode.timeout;
        break;
      default:
        code = SensorErrorCode.unknown;
    }

    return SensorError(
      code: code,
      message: message,
      details: '${e.code}: ${e.message}',
    );
  }

  /// Dispose resources
  void dispose() {
    _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    _heartRateStream = null;
    stopPermissionMonitoring();
    _permissionStateController.close();
  }
}
