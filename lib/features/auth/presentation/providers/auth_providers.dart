import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/providers/core_providers.dart';
import 'package:legalgo_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:legalgo_mobile/features/auth/data/dtos/auth_dtos.dart';
import 'package:legalgo_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:legalgo_mobile/features/auth/domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  const AuthState.unknown()
    : status = AuthStatus.unknown,
      user = null,
      isLoading = false,
      errorMessage = null;

  final AuthStatus status;
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isAdmin => user?.role == UserRole.admin;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.unknown());

  final AuthRepository _repository;

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.restoreSession();
      if (session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (_) {
      await _repository.clearLocalSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.login(
        LoginRequestDto(email: email.trim(), password: password),
      );
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.register(
        RegisterRequestDto(
          email: email.trim(),
          password: password,
          phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        ),
      );
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) {
    return _repository.forgotPassword(email.trim());
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.logout();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
