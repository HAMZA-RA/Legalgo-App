import 'package:dio/dio.dart';
import 'package:legalgo_mobile/core/storage/secure_token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required SecureTokenStorage tokenStorage,
  })  : _dio = dio,
        _refreshDio = refreshDio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final Dio _refreshDio;
  final SecureTokenStorage _tokenStorage;
  Future<TokenPair?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final request = err.requestOptions;
    final alreadyRetried = request.extra['legalgoRetried'] == true;
    final isRefreshRequest = request.path.contains('/auth/refresh');

    if (statusCode != 401 || alreadyRetried || isRefreshRequest) {
      handler.next(err);
      return;
    }

    try {
      final tokens = await _refreshTokens();
      if (tokens == null) {
        await _tokenStorage.clear();
        handler.next(err);
        return;
      }

      final retryOptions = Options(
        method: request.method,
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
        responseType: request.responseType,
        contentType: request.contentType,
        followRedirects: request.followRedirects,
        validateStatus: request.validateStatus,
        receiveDataWhenStatusError: request.receiveDataWhenStatusError,
        extra: {...request.extra, 'legalgoRetried': true},
      );

      final response = await _dio.request<Object?>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: retryOptions,
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
        onSendProgress: request.onSendProgress,
      );
      handler.resolve(response);
    } catch (_) {
      await _tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<TokenPair?> _refreshTokens() {
    _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<TokenPair?> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final body = response.data?['data'];
    if (body is! Map<String, dynamic>) return null;

    final accessToken = body['accessToken'] as String?;
    final rotatedRefreshToken = body['refreshToken'] as String?;
    if (accessToken == null || rotatedRefreshToken == null) return null;

    final tokens = TokenPair(
      accessToken: accessToken,
      refreshToken: rotatedRefreshToken,
    );
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }
}
