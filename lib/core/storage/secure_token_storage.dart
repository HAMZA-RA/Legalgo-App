import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:legalgo_mobile/core/constants/storage_keys.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  bool get isComplete => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}

class SecureTokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<TokenPair?> readTokens() async {
    final accessToken = await _storage.read(key: StorageKeys.accessToken);
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    if (accessToken == null || refreshToken == null) return null;
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> saveTokens(TokenPair tokens) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: tokens.accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken),
    ]);
  }

  Future<AuthUser?> readCachedUser() async {
    final raw = await _storage.read(key: StorageKeys.cachedUser);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AuthUser.fromJson(decoded);
  }

  Future<void> saveCachedUser(AuthUser user) {
    return _storage.write(
      key: StorageKeys.cachedUser,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.cachedUser),
    ]);
  }
}
