import 'package:legalgo_mobile/features/auth/data/dtos/auth_dtos.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();
  Future<AuthSession> login(LoginRequestDto dto);
  Future<AuthSession> register(RegisterRequestDto dto);
  Future<AuthSession> refresh(String refreshToken);
  Future<void> forgotPassword(String email);
  Future<AuthUser> currentUser();
  Future<void> logout();
  Future<void> clearLocalSession();
}
