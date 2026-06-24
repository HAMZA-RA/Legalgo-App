import 'package:dio/dio.dart';
import 'package:legalgo_mobile/core/errors/app_exception.dart';

AppException mapDioException(Object error) {
  if (error is DioException) {
    final response = error.response;
    final data = response?.data;
    final message =
        _extractMessage(data) ??
        error.message ??
        'Impossible de contacter le serveur LegalGo.';
    if (response?.statusCode == 401) {
      return UnauthorizedException(message);
    }
    return AppException(
      message,
      statusCode: response?.statusCode,
      details: data,
    );
  }

  if (error is AppException) return error;
  return AppException(error.toString(), details: error);
}

String? _extractMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is List) return message.join(' ');
    if (message is String) return message;
  }
  return null;
}
