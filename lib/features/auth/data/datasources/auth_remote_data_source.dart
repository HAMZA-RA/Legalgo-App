import 'package:dio/dio.dart';
import 'package:legalgo_mobile/core/network/api_envelope.dart';
import 'package:legalgo_mobile/features/auth/data/dtos/auth_dtos.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> login(LoginRequestDto dto) async {
    final response = await _dio.post<Object?>('/auth/login', data: dto.toJson());
    return ApiEnvelope.unwrap(
      response.data,
      (data) => AuthResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AuthResponseDto> register(RegisterRequestDto dto) async {
    final response = await _dio.post<Object?>('/auth/register', data: dto.toJson());
    return ApiEnvelope.unwrap(
      response.data,
      (data) => AuthResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AuthResponseDto> refresh(String refreshToken) async {
    final response = await _dio.post<Object?>(
      '/auth/refresh',
      data: RefreshTokenRequestDto(refreshToken: refreshToken).toJson(),
    );
    return ApiEnvelope.unwrap(
      response.data,
      (data) => AuthResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AuthUser> me() async {
    final response = await _dio.get<Object?>('/users/me');
    return ApiEnvelope.unwrap(
      response.data,
      (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await _dio.post<Object?>('/auth/logout');
  }
}
