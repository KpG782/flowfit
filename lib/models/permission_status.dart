enum PermissionStatus {
  granted,
  denied,
  notDetermined;

  String toJson() => name;

  static PermissionStatus fromJson(String json) {
    return PermissionStatus.values.firstWhere(
      (status) => status.name == json,
      orElse: () => PermissionStatus.notDetermined,
    );
  }
}
