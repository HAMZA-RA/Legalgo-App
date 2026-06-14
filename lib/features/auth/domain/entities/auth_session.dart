import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required AuthUser user,
    required String accessToken,
    required String refreshToken,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);
}
