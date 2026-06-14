import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.paymentSuccessUrl,
    required this.paymentCancelUrl,
    required this.enableNetworkLogs,
  });

  factory AppConfig.fromEnvironment() {
    const environment = String.fromEnvironment(
      'LEGALGO_ENV',
      defaultValue: 'development',
    );
    const explicitApiBaseUrl = String.fromEnvironment('LEGALGO_API_BASE_URL');
    const deviceApiHost = String.fromEnvironment('LEGALGO_API_HOST');
    const deviceApiScheme = String.fromEnvironment(
      'LEGALGO_API_SCHEME',
      defaultValue: 'http',
    );
    const deviceApiPort = String.fromEnvironment(
      'LEGALGO_API_PORT',
      defaultValue: '3001',
    );

    return AppConfig(
      environment: environment,
      apiBaseUrl: _resolveApiBaseUrl(
        explicitApiBaseUrl: explicitApiBaseUrl,
        deviceApiHost: deviceApiHost,
        deviceApiScheme: deviceApiScheme,
        deviceApiPort: deviceApiPort,
      ),
      paymentSuccessUrl: const String.fromEnvironment(
        'LEGALGO_WEB_SUCCESS_URL',
        defaultValue: 'legalgo://payment/success',
      ),
      paymentCancelUrl: const String.fromEnvironment(
        'LEGALGO_WEB_CANCEL_URL',
        defaultValue: 'legalgo://payment/cancel',
      ),
      enableNetworkLogs: environment != 'production',
    );
  }

  final String environment;
  final String apiBaseUrl;
  final String paymentSuccessUrl;
  final String paymentCancelUrl;
  final bool enableNetworkLogs;

  bool get isProduction => environment == 'production';

  static String _resolveApiBaseUrl({
    required String explicitApiBaseUrl,
    required String deviceApiHost,
    required String deviceApiScheme,
    required String deviceApiPort,
  }) {
    if (explicitApiBaseUrl.isNotEmpty) {
      return explicitApiBaseUrl;
    }

    if (deviceApiHost.isNotEmpty) {
      return '$deviceApiScheme://$deviceApiHost:$deviceApiPort/api/v1';
    }

    if (kIsWeb) {
      return 'http://localhost:3001/api/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001/api/v1';
    }

    return 'http://localhost:3001/api/v1';
  }
}
