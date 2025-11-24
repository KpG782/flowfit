import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/sensor_status.dart';

void main() {
  group('HeartRateData', () {
    test('toJson serializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final heartRateData = HeartRateData(
        bpm: 75,
        timestamp: timestamp,
        status: SensorStatus.active,
      );

      final json = heartRateData.toJson();

      expect(json['bpm'], equals(75));
      expect(json['timestamp'], equals(timestamp.millisecondsSinceEpoch));
      expect(json['status'], equals('active'));
    });

    test('fromJson deserializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final json = {
        'bpm': 75,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': 'active',
      };

      final heartRateData = HeartRateData.fromJson(json);

      expect(heartRateData.bpm, equals(75));
      expect(heartRateData.timestamp, equals(timestamp));
      expect(heartRateData.status, equals(SensorStatus.active));
    });

    test('round-trip serialization preserves data', () {
      // Use a timestamp without microseconds since JSON serialization uses milliseconds
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      );
      final original = HeartRateData(
        bpm: 82,
        timestamp: timestamp,
        status: SensorStatus.inactive,
      );

      final json = original.toJson();
      final deserialized = HeartRateData.fromJson(json);

      expect(deserialized, equals(original));
    });

    test('equality works correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final data1 = HeartRateData(
        bpm: 75,
        timestamp: timestamp,
        status: SensorStatus.active,
      );
      final data2 = HeartRateData(
        bpm: 75,
        timestamp: timestamp,
        status: SensorStatus.active,
      );
      final data3 = HeartRateData(
        bpm: 80,
        timestamp: timestamp,
        status: SensorStatus.active,
      );

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('toString returns formatted string', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final heartRateData = HeartRateData(
        bpm: 75,
        timestamp: timestamp,
        status: SensorStatus.active,
      );

      final string = heartRateData.toString();

      expect(string, contains('75'));
      expect(string, contains('active'));
    });
  });
}
