// ignore_for_file: use_null_aware_elements

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:legalgo_mobile/features/shared/domain/downloaded_file.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';

class DocumentUploadValidationException implements Exception {
  const DocumentUploadValidationException(this.message);

  final String message;
}

class PaymentCheckoutException implements Exception {
  const PaymentCheckoutException(this.message);

  final String message;
}

class LegalGoRepository {
  const LegalGoRepository(this._dio);

  final Dio _dio;

  Future<List<LegalRequest>> fetchClientRequests() async {
    final data = await _get('/requests');
    return _parse(
      '/requests',
      data,
      () => unwrapList(data).map(LegalRequest.fromJson).toList(),
    );
  }

  Future<LegalRequest> fetchRequest(String id) async {
    final endpoint = '/requests/$id';
    final data = await _get(endpoint);
    return _parse(
      endpoint,
      data,
      () => LegalRequest.fromJson(unwrapData(data)),
    );
  }

  Future<RequestDocumentsPayload> fetchRequestDocuments(
    String requestId,
  ) async {
    final endpoint = '/requests/$requestId/documents';
    final data = await _get(endpoint);
    return _parse(endpoint, data, () {
      return RequestDocumentsPayload.fromJson(
        data is Map<String, dynamic> && data.containsKey('data')
            ? data['data']
            : data,
      );
    });
  }

  Future<LegalDocument> uploadDocument({
    required String requestId,
    required String title,
    required String type,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? message,
    String? requiredDocumentId,
  }) async {
    const endpoint = '/documents/upload';
    final validRequestId = BigInt.tryParse(requestId);
    final validRequiredDocumentId = requiredDocumentId == null
        ? null
        : BigInt.tryParse(requiredDocumentId);
    final validatedTitle = title.trim();
    final validatedType = type.trim();
    final normalizedFileName = fileName.trim();
    final extension = normalizedFileName.contains('.')
        ? normalizedFileName.split('.').last.toLowerCase()
        : '';
    const allowedExtensions = {'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'};

    if (validRequestId == null || validRequestId < BigInt.one) {
      throw const DocumentUploadValidationException(
        'Identifiant de demande invalide',
      );
    }
    if (requiredDocumentId != null &&
        (validRequiredDocumentId == null ||
            validRequiredDocumentId < BigInt.one)) {
      throw const DocumentUploadValidationException(
        'Identifiant de document requis invalide',
      );
    }
    if (validatedTitle.isEmpty ||
        validatedType.isEmpty ||
        bytes.isEmpty ||
        normalizedFileName.isEmpty) {
      throw const DocumentUploadValidationException(
        'Échec de l’envoi du document',
      );
    }
    if (!allowedExtensions.contains(extension)) {
      throw const DocumentUploadValidationException('Format non autorisé');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const DocumentUploadValidationException(
        'Le fichier dépasse la limite de 10 Mo',
      );
    }

    final formData = FormData.fromMap({
      'requestId': requestId,
      'title': title,
      'type': type,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
      if (validRequiredDocumentId != null)
        'requiredDocumentId': requiredDocumentId,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: normalizedFileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    debugPrint(
      '[LegalGo API] POST $endpoint multipart '
      'requestId=$requestId title=$title type=$type '
      'requiredDocumentId=$requiredDocumentId file=$normalizedFileName '
      'bytes=${bytes.length}',
    );
    final response = await _dio.post<Object?>(endpoint, data: formData);
    _logResponse(endpoint, response);
    return _parse(
      endpoint,
      response.data,
      () => LegalDocument.fromJson(unwrapData(response.data)),
    );
  }

  Future<DownloadedFile> downloadDocument(LegalDocument document) async {
    final endpoint = '/documents/${document.id}/download';
    debugPrint('[LegalGo API] GET $endpoint');
    final response = await _dio.get<List<int>>(
      endpoint,
      options: Options(responseType: ResponseType.bytes),
    );
    debugPrint(
      '[LegalGo API] $endpoint status=${response.statusCode} bytes=${response.data?.length ?? 0}',
    );
    final contentDisposition = response.headers.value('content-disposition');
    return DownloadedFile(
      fileName:
          _downloadNameFromHeader(contentDisposition) ?? document.downloadName,
      mimeType:
          response.headers.value('content-type') ??
          document.mimeType ??
          'application/octet-stream',
      bytes: Uint8List.fromList(response.data ?? const []),
    );
  }

  Future<List<Payment>> fetchClientPayments() async {
    final data = await _get('/payments');
    return _parse(
      '/payments',
      data,
      () => unwrapList(data).map(Payment.fromJson).toList(),
    );
  }

  Future<CheckoutSession> createRequestCheckoutSession(String requestId) async {
    final validRequestId = BigInt.tryParse(requestId);
    if (validRequestId == null || validRequestId < BigInt.one) {
      throw const PaymentCheckoutException('Identifiant de demande invalide');
    }

    final endpoint = '/payments/requests/$requestId/checkout';
    debugPrint('[LegalGo API] POST $endpoint');
    final response = await _dio.post<Object?>(endpoint);
    _logResponse(endpoint, response);
    return _parse(endpoint, response.data, () {
      final checkout = CheckoutSession.fromJson(unwrapData(response.data));
      final uri = Uri.tryParse(checkout.checkoutUrl);
      if (checkout.checkoutUrl.isEmpty ||
          uri == null ||
          !uri.hasScheme ||
          !{'http', 'https'}.contains(uri.scheme)) {
        throw const PaymentCheckoutException(
          'Impossible de démarrer le paiement',
        );
      }
      return checkout;
    });
  }

  Future<List<LegalGoNotification>> fetchNotifications({
    required bool admin,
  }) async {
    final endpoint = admin ? '/admin/notifications' : '/notifications';
    final data = await _get(endpoint);
    return _parse(
      endpoint,
      data,
      () => unwrapList(data).map(LegalGoNotification.fromJson).toList(),
    );
  }

  Future<void> markNotificationRead({
    required String notificationId,
    required bool admin,
  }) async {
    final endpoint = admin
        ? '/admin/notifications/$notificationId/read'
        : '/notifications/$notificationId/read';
    await _patch(endpoint, const {});
  }

  Future<void> markAllNotificationsRead({required bool admin}) async {
    final endpoint = admin
        ? '/admin/notifications/read-all'
        : '/notifications/read-all';
    await _patch(endpoint, const {});
  }

  Future<LegalGoUser> fetchMe() async {
    final data = await _get('/users/me');
    return _parse(
      '/users/me',
      data,
      () => LegalGoUser.fromJson(unwrapData(data)),
    );
  }

  Future<LegalGoUser> updateMe({String? email, String? phone}) async {
    final data = await _patch('/users/me', {
      if (email != null) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _parse(
      '/users/me',
      data,
      () => LegalGoUser.fromJson(unwrapData(data)),
    );
  }

  Future<LegalGoUser> updateProfile(Map<String, Object?> payload) async {
    final data = await _patch('/users/me/profile', payload);
    return _parse(
      '/users/me/profile',
      data,
      () => LegalGoUser.fromJson(unwrapData(data)),
    );
  }

  Future<AdminStats> fetchAdminStats() async {
    final data = await _get('/admin/stats');
    return _parse(
      '/admin/stats',
      data,
      () => AdminStats.fromJson(unwrapData(data)),
    );
  }

  Future<AdminDashboardStats> fetchAdminDashboard({
    String period = '30d',
  }) async {
    final data = await _get(
      '/admin/stats/dashboard',
      queryParameters: {'period': period},
    );
    return _parse(
      '/admin/stats/dashboard',
      data,
      () => AdminDashboardStats.fromJson(unwrapData(data)),
    );
  }

  Future<PaginatedResult<LegalGoUser>> fetchAdminUsers({
    String? search,
    String? role,
    String? status,
    String? profileType,
    int page = 1,
    int limit = 20,
  }) async {
    const endpoint = '/admin/users';
    final data = await _get(
      endpoint,
      queryParameters: _cleanQuery({
        'search': search,
        'role': role ?? 'client',
        'status': status,
        'profileType': profileType,
        'page': page,
        'limit': limit,
      }),
    );
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    return _parse(
      endpoint,
      data,
      () => PaginatedResult.fromJson(unwrapped, LegalGoUser.fromJson),
    );
  }

  Future<PaginatedResult<LegalRequest>> fetchAdminRequests({
    String? search,
    String? serviceId,
    String? status,
    String? paymentStatus,
    int page = 1,
    int limit = 20,
  }) async {
    const endpoint = '/admin/requests';
    final data = await _get(
      endpoint,
      queryParameters: _cleanQuery({
        'search': search,
        'serviceId': serviceId,
        'status': status,
        'paymentStatus': paymentStatus,
        'page': page,
        'limit': limit,
      }),
    );
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    return _parse(
      endpoint,
      data,
      () => PaginatedResult.fromJson(unwrapped, LegalRequest.fromJson),
    );
  }

  Future<LegalRequest> updateRequestStatus(
    String requestId,
    String status, {
    String? reason,
  }) async {
    final endpoint = '/admin/requests/$requestId/status';
    final data = await _patch(endpoint, {
      'status': status,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    return _parse(
      endpoint,
      data,
      () => LegalRequest.fromJson(unwrapData(data)),
    );
  }

  Future<LegalDocument> updateDocumentStatus(
    String documentId,
    String status, {
    String? rejectionReason,
  }) async {
    final endpoint = '/admin/documents/$documentId/status';
    final data = await _patch(endpoint, {
      'status': status,
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
        'rejectionReason': rejectionReason.trim(),
    });
    return _parse(
      endpoint,
      data,
      () => LegalDocument.fromJson(unwrapData(data)),
    );
  }

  Future<LegalDocument> requestDocument({
    required String requestId,
    required String title,
    required String type,
    required String message,
  }) async {
    final endpoint = '/admin/requests/$requestId/documents/request';
    final data = await _post(endpoint, {
      'title': title.trim(),
      'type': type.trim(),
      'message': message.trim(),
    });
    return _parse(
      endpoint,
      data,
      () => LegalDocument.fromJson(unwrapData(data)),
    );
  }

  Future<void> sendSubscriptionReminder(String subscriptionId) async {
    final endpoint = '/admin/subscriptions/$subscriptionId/reminder';
    await _post(endpoint, const {});
  }

  Future<PaginatedResult<Payment>> fetchAdminPayments({
    String? search,
    String? status,
    String? serviceId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    const endpoint = '/admin/payments';
    final data = await _get(
      endpoint,
      queryParameters: _cleanQuery({
        'search': search,
        'status': status,
        'serviceId': serviceId,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'page': page,
        'limit': limit,
      }),
    );
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    return _parse(
      endpoint,
      data,
      () => PaginatedResult.fromJson(unwrapped, Payment.fromJson),
    );
  }

  Future<List<DomiciliationSubscription>> fetchAdminSubscriptions({
    String? plan,
    String? status,
  }) async {
    const endpoint = '/admin/subscriptions';
    final data = await _get(
      endpoint,
      queryParameters: _cleanQuery({'plan': plan, 'status': status}),
    );
    return _parse(
      endpoint,
      data,
      () => unwrapList(data).map(DomiciliationSubscription.fromJson).toList(),
    );
  }

  Future<List<LegalServiceSummary>> fetchAdminLegalServices() async {
    const endpoint = '/admin/legal-services';
    final data = await _get(endpoint);
    return _parse(
      endpoint,
      data,
      () => unwrapList(data).map(LegalServiceSummary.fromJson).toList(),
    );
  }

  Future<Object?> _get(
    String endpoint, {
    Map<String, Object?>? queryParameters,
  }) async {
    debugPrint(
      '[LegalGo API] GET $endpoint query=${queryParameters ?? const {}}',
    );
    final response = await _dio.get<Object?>(
      endpoint,
      queryParameters: queryParameters,
    );
    _logResponse(endpoint, response);
    return response.data;
  }

  Future<Object?> _patch(String endpoint, Map<String, Object?> payload) async {
    debugPrint('[LegalGo API] PATCH $endpoint body=${_encode(payload)}');
    final response = await _dio.patch<Object?>(endpoint, data: payload);
    _logResponse(endpoint, response);
    return response.data;
  }

  Future<Object?> _post(String endpoint, Map<String, Object?> payload) async {
    debugPrint('[LegalGo API] POST $endpoint body=${_encode(payload)}');
    final response = await _dio.post<Object?>(endpoint, data: payload);
    _logResponse(endpoint, response);
    return response.data;
  }

  T _parse<T>(String endpoint, Object? body, T Function() parser) {
    try {
      return parser();
    } catch (error, stackTrace) {
      debugPrint('[LegalGo API] PARSE ERROR $endpoint error=$error');
      debugPrint('[LegalGo API] PARSE BODY $endpoint ${_encode(body)}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void _logResponse(String endpoint, Response<Object?> response) {
    debugPrint('[LegalGo API] $endpoint status=${response.statusCode}');
    debugPrint('[LegalGo API] $endpoint body=${_encode(response.data)}');
  }

  Map<String, Object?> _cleanQuery(Map<String, Object?> query) {
    final cleaned = <String, Object?>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && (value.trim().isEmpty || value == 'all')) continue;
      cleaned[entry.key] = value;
    }
    return cleaned;
  }

  String _encode(Object? value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  String? _downloadNameFromHeader(String? header) {
    if (header == null) return null;
    final match = RegExp('filename="?([^";]+)"?').firstMatch(header);
    if (match == null) return null;
    return Uri.decodeFull(match.group(1) ?? '');
  }
}

String backendResponseBody(Object error) {
  if (error is DioException) {
    final response = error.response;
    if (response == null) return error.message ?? error.toString();
    final body = response.data;
    try {
      return 'HTTP ${response.statusCode}: ${jsonEncode(body)}';
    } catch (_) {
      return 'HTTP ${response.statusCode}: $body';
    }
  }
  return error.toString();
}
