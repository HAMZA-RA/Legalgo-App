// ignore_for_file: use_null_aware_elements

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:legalgo_mobile/features/shared/domain/downloaded_file.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';

class LegalGoRepository {
  const LegalGoRepository(this._dio);

  final Dio _dio;

  Future<List<LegalRequest>> fetchClientRequests() async {
    final data = await _get('/requests');
    return _parse('/requests', data, () => unwrapList(data).map(LegalRequest.fromJson).toList());
  }

  Future<LegalRequest> fetchRequest(String id) async {
    final endpoint = '/requests/$id';
    final data = await _get(endpoint);
    return _parse(endpoint, data, () => LegalRequest.fromJson(unwrapData(data)));
  }

  Future<RequestDocumentsPayload> fetchRequestDocuments(String requestId) async {
    final endpoint = '/requests/$requestId/documents';
    final data = await _get(endpoint);
    return _parse(endpoint, data, () {
      return RequestDocumentsPayload.fromJson(data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data);
    });
  }

  Future<DownloadedFile> downloadDocument(LegalDocument document) async {
    final endpoint = '/documents/${document.id}/download';
    debugPrint('[LegalGo API] GET $endpoint');
    final response = await _dio.get<List<int>>(
      endpoint,
      options: Options(responseType: ResponseType.bytes),
    );
    debugPrint('[LegalGo API] $endpoint status=${response.statusCode} bytes=${response.data?.length ?? 0}');
    final contentDisposition = response.headers.value('content-disposition');
    return DownloadedFile(
      fileName: _downloadNameFromHeader(contentDisposition) ?? document.downloadName,
      mimeType: response.headers.value('content-type') ?? document.mimeType ?? 'application/octet-stream',
      bytes: Uint8List.fromList(response.data ?? const []),
    );
  }

  Future<List<Payment>> fetchClientPayments() async {
    final data = await _get('/payments');
    return _parse('/payments', data, () => unwrapList(data).map(Payment.fromJson).toList());
  }

  Future<LegalGoUser> fetchMe() async {
    final data = await _get('/users/me');
    return _parse('/users/me', data, () => LegalGoUser.fromJson(unwrapData(data)));
  }

  Future<LegalGoUser> updateMe({String? email, String? phone}) async {
    final data = await _patch('/users/me', {
      if (email != null) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _parse('/users/me', data, () => LegalGoUser.fromJson(unwrapData(data)));
  }

  Future<LegalGoUser> updateProfile(Map<String, Object?> payload) async {
    final data = await _patch('/users/me/profile', payload);
    return _parse('/users/me/profile', data, () => LegalGoUser.fromJson(unwrapData(data)));
  }

  Future<AdminStats> fetchAdminStats() async {
    final data = await _get('/admin/stats');
    return _parse('/admin/stats', data, () => AdminStats.fromJson(unwrapData(data)));
  }

  Future<AdminDashboardStats> fetchAdminDashboard({String period = '30d'}) async {
    final data = await _get('/admin/stats/dashboard', queryParameters: {'period': period});
    return _parse('/admin/stats/dashboard', data, () => AdminDashboardStats.fromJson(unwrapData(data)));
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
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data;
    return _parse(endpoint, data, () => PaginatedResult.fromJson(unwrapped, LegalGoUser.fromJson));
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
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data;
    return _parse(endpoint, data, () => PaginatedResult.fromJson(unwrapped, LegalRequest.fromJson));
  }

  Future<LegalRequest> updateRequestStatus(String requestId, String status, {String? reason}) async {
    final endpoint = '/admin/requests/$requestId/status';
    final data = await _patch(endpoint, {
      'status': status,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    return _parse(endpoint, data, () => LegalRequest.fromJson(unwrapData(data)));
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
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data;
    return _parse(endpoint, data, () => PaginatedResult.fromJson(unwrapped, Payment.fromJson));
  }

  Future<List<DomiciliationSubscription>> fetchAdminSubscriptions({String? plan, String? status}) async {
    const endpoint = '/admin/subscriptions';
    final data = await _get(endpoint, queryParameters: _cleanQuery({'plan': plan, 'status': status}));
    return _parse(endpoint, data, () => unwrapList(data).map(DomiciliationSubscription.fromJson).toList());
  }

  Future<List<LegalServiceSummary>> fetchAdminLegalServices() async {
    const endpoint = '/admin/legal-services';
    final data = await _get(endpoint);
    return _parse(endpoint, data, () => unwrapList(data).map(LegalServiceSummary.fromJson).toList());
  }

  Future<Object?> _get(String endpoint, {Map<String, Object?>? queryParameters}) async {
    debugPrint('[LegalGo API] GET $endpoint query=${queryParameters ?? const {}}');
    final response = await _dio.get<Object?>(endpoint, queryParameters: queryParameters);
    _logResponse(endpoint, response);
    return response.data;
  }

  Future<Object?> _patch(String endpoint, Map<String, Object?> payload) async {
    debugPrint('[LegalGo API] PATCH $endpoint body=${_encode(payload)}');
    final response = await _dio.patch<Object?>(endpoint, data: payload);
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

