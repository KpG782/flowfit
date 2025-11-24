enum SensorErrorCode {
  permissionDenied,
  serviceUnavailable,
  connectionFailed,
  sensorNotSupported,
  sensorUnavailable,
  timeout,
  unknown;

  String toJson() => name;

  static SensorErrorCode fromJson(String json) {
    return SensorErrorCode.values.firstWhere(
      (code) => code.name == json,
      orElse: () => SensorErrorCode.unknown,
    );
  }
}
