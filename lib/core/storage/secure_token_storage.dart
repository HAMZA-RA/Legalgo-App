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
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;
  AuthUser? _cachedUser;

  Future<TokenPair?> readTokens() async {
    if (_accessToken != null && _refreshToken != null) {
      return TokenPair(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
    }
    final accessToken = await _storage.read(key: StorageKeys.accessToken);
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    if (accessToken == null || refreshToken == null) return null;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<String?> readAccessToken() {
    if (_accessToken != null) return Future.value(_accessToken);
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<String?> readRefreshToken() {
    if (_refreshToken != null) return Future.value(_refreshToken);
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> saveTokens(TokenPair tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: tokens.accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken),
    ]);
  }

  Future<AuthUser?> readCachedUser() async {
    if (_cachedUser != null) return _cachedUser;
    final raw = await _storage.read(key: StorageKeys.cachedUser);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cachedUser = AuthUser.fromJson(decoded);
    return _cachedUser;
  }

  Future<void> saveCachedUser(AuthUser user) {
    _cachedUser = user;
    return _storage.write(
      key: StorageKeys.cachedUser,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _cachedUser = null;
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.cachedUser),
    ]);
  }
}
