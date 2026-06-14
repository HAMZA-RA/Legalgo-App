import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

@freezed
abstract class LoginRequestDto with _$LoginRequestDto {
  const factory LoginRequestDto({
    required String email,
    required String password,
  }) = _LoginRequestDto;

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);
}

@freezed
abstract class RegisterRequestDto with _$RegisterRequestDto {
  const factory RegisterRequestDto({
    required String email,
    required String password,
    String? phone,
  }) = _RegisterRequestDto;

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);
}

@freezed
abstract class RefreshTokenRequestDto with _$RefreshTokenRequestDto {
  const factory RefreshTokenRequestDto({required String refreshToken}) =
      _RefreshTokenRequestDto;

  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestDtoFromJson(json);
}

@freezed
abstract class AuthResponseDto with _$AuthResponseDto {
  const factory AuthResponseDto({
    required AuthUser user,
    required String accessToken,
    required String refreshToken,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}

extension AuthResponseDtoMapper on AuthResponseDto {
  AuthSession toDomain() => AuthSession(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
