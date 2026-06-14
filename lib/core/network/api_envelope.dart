class ApiEnvelope<T> {
  const ApiEnvelope({required this.success, required this.data});

  final bool success;
  final T data;

  static T unwrap<T>(Object? json, T Function(Object? data) fromJson) {
    if (json is Map<String, dynamic> && json.containsKey('data')) {
      return fromJson(json['data']);
    }
    return fromJson(json);
  }
}
