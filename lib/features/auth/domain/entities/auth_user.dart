import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:legalgo_mobile/core/json/json_converters.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

enum UserRole {
  @JsonValue('client')
  client,
  @JsonValue('admin')
  admin,
}

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    @StringIdJsonConverter() required String id,
    required String email,
    String? phone,
    required UserRole role,
    required bool status,
    DateTime? createdAt,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
