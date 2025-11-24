enum SensorStatus {
  active,
  inactive,
  error,
  unavailable;

  String toJson() => name;

  static SensorStatus fromJson(String json) {
    return SensorStatus.values.firstWhere(
      (status) => status.name == json,
      orElse: () => SensorStatus.unavailable,
    );
  }
}
