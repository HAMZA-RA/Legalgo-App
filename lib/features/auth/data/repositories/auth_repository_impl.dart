import 'package:legalgo_mobile/core/network/api_error_mapper.dart';
import 'package:legalgo_mobile/core/storage/secure_token_storage.dart';
import 'package:legalgo_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:legalgo_mobile/features/auth/data/dtos/auth_dtos.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:legalgo_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureTokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureTokenStorage _tokenStorage;

  @override
  Future<AuthSession?> restoreSession() async {
    final tokens = await _tokenStorage.readTokens();
    if (tokens == null || !tokens.isComplete) return null;

    try {
      final freshUser = await _remoteDataSource.me();
      await _tokenStorage.saveCachedUser(freshUser);
      return AuthSession(
        user: freshUser,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AuthSession> login(LoginRequestDto dto) async {
    try {
      final session = (await _remoteDataSource.login(dto)).toDomain();
      await _persist(session);
      return session;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AuthSession> register(RegisterRequestDto dto) async {
    try {
      final session = (await _remoteDataSource.register(dto)).toDomain();
      await _persist(session);
      return session;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    try {
      final session = (await _remoteDataSource.refresh(refreshToken)).toDomain();
      await _persist(session);
      return session;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AuthUser> currentUser() async {
    try {
      final user = await _remoteDataSource.me();
      await _tokenStorage.saveCachedUser(user);
      return user;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<void> clearLocalSession() => _tokenStorage.clear();

  Future<void> _persist(AuthSession session) async {
    await _tokenStorage.saveTokens(
      TokenPair(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      ),
    );
    await _tokenStorage.saveCachedUser(session.user);
  }
}

