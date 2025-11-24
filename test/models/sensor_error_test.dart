import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/models/sensor_error.dart';
import 'package:flowfit/models/sensor_error_code.dart';

void main() {
  group('SensorError', () {
    test('creates error with all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final error = SensorError(
        code: SensorErrorCode.permissionDenied,
        message: 'Permission denied',
        details: 'User denied body sensor permission',
        timestamp: timestamp,
      );

      expect(error.code, equals(SensorErrorCode.permissionDenied));
      expect(error.message, equals('Permission denied'));
      expect(error.details, equals('User denied body sensor permission'));
      expect(error.timestamp, equals(timestamp));
    });

    test('creates error without optional fields', () {
      final error = SensorError(
        code: SensorErrorCode.timeout,
        message: 'Operation timed out',
      );

      expect(error.code, equals(SensorErrorCode.timeout));
      expect(error.message, equals('Operation timed out'));
      expect(error.details, isNull);
      expect(error.timestamp, isNotNull);
    });

    test('toJson serializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final error = SensorError(
        code: SensorErrorCode.connectionFailed,
        message: 'Failed to connect',
        details: 'Network unavailable',
        timestamp: timestamp,
      );

      final json = error.toJson();

      expect(json['code'], equals('connectionFailed'));
      expect(json['message'], equals('Failed to connect'));
      expect(json['details'], equals('Network unavailable'));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
    });

    test('fromJson deserializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final json = {
        'code': 'sensorUnavailable',
        'message': 'Sensor not available',
        'details': 'Hardware error',
        'timestamp': timestamp.toIso8601String(),
      };

      final error = SensorError.fromJson(json);

      expect(error.code, equals(SensorErrorCode.sensorUnavailable));
      expect(error.message, equals('Sensor not available'));
      expect(error.details, equals('Hardware error'));
      expect(error.timestamp, equals(timestamp));
    });

    test('round-trip serialization preserves data', () {
      final original = SensorError(
        code: SensorErrorCode.serviceUnavailable,
        message: 'Service unavailable',
        details: 'Samsung Health not installed',
        timestamp: DateTime(2024, 1, 15, 10, 30, 0),
      );

      final json = original.toJson();
      final deserialized = SensorError.fromJson(json);

      expect(deserialized, equals(original));
    });

    test('toString formats error correctly', () {
      final error = SensorError(
        code: SensorErrorCode.permissionDenied,
        message: 'Permission denied',
        details: 'User denied permission',
      );

      final string = error.toString();

      expect(string, contains('permissionDenied'));
      expect(string, contains('Permission denied'));
      expect(string, contains('User denied permission'));
    });

    test('toString formats error without details', () {
      final error = SensorError(
        code: SensorErrorCode.unknown,
        message: 'Unknown error',
      );

      final string = error.toString();

      expect(string, contains('unknown'));
      expect(string, contains('Unknown error'));
      expect(string, isNot(contains('details:')));
    });

    test('equality works correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final error1 = SensorError(
        code: SensorErrorCode.timeout,
        message: 'Timeout',
        details: 'Operation timed out',
        timestamp: timestamp,
      );
      final error2 = SensorError(
        code: SensorErrorCode.timeout,
        message: 'Timeout',
        details: 'Operation timed out',
        timestamp: timestamp,
      );
      final error3 = SensorError(
        code: SensorErrorCode.timeout,
        message: 'Different message',
        details: 'Operation timed out',
        timestamp: timestamp,
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });
  });
}
