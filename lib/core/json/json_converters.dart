import 'package:json_annotation/json_annotation.dart';

class StringIdJsonConverter implements JsonConverter<String, Object?> {
  const StringIdJsonConverter();

  @override
  String fromJson(Object? json) {
    if (json == null) {
      throw const FormatException('ID value cannot be null');
    }
    if (json is String) return json;
    if (json is int) return json.toString();
    if (json is num) {
      if (json % 1 == 0) return json.toInt().toString();
      return json.toString();
    }
    throw FormatException('Unsupported ID value: $json');
  }

  @override
  Object toJson(String object) => object;
}

class NullableStringIdJsonConverter implements JsonConverter<String?, Object?> {
  const NullableStringIdJsonConverter();

  @override
  String? fromJson(Object? json) {
    if (json == null) return null;
    return const StringIdJsonConverter().fromJson(json);
  }

  @override
  Object? toJson(String? object) => object;
}
