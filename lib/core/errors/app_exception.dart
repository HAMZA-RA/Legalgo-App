class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expirée']);
}
