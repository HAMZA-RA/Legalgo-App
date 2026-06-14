import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/app/config/app_config.dart';
import 'package:legalgo_mobile/core/network/auth_interceptor.dart';
import 'package:legalgo_mobile/core/storage/secure_token_storage.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage(ref.watch(secureStorageProvider));
});

final refreshDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(BaseOptions(baseUrl: config.apiBaseUrl));
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      refreshDio: ref.watch(refreshDioProvider),
      tokenStorage: ref.watch(tokenStorageProvider),
    ),
  );

  if (config.enableNetworkLogs) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  return dio;
});
