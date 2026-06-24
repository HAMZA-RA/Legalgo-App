import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/providers/core_providers.dart';
import 'package:legalgo_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:legalgo_mobile/features/shared/data/legalgo_repository.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';

final legalGoRepositoryProvider = Provider<LegalGoRepository>((ref) {
  return LegalGoRepository(ref.watch(dioProvider));
});

void _requireAuthenticatedSession(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    throw StateError('Authenticated session is required.');
  }
}

final clientRequestsProvider = FutureProvider.autoDispose<List<LegalRequest>>((
  ref,
) {
  _requireAuthenticatedSession(ref);
  return ref.watch(legalGoRepositoryProvider).fetchClientRequests();
});

final requestDetailsProvider = FutureProvider.autoDispose
    .family<LegalRequest, String>((ref, requestId) {
      _requireAuthenticatedSession(ref);
      return ref.watch(legalGoRepositoryProvider).fetchRequest(requestId);
    });

final requestDocumentsProvider = FutureProvider.autoDispose
    .family<RequestDocumentsPayload, String>((ref, requestId) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchRequestDocuments(requestId);
    });

final clientPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) {
  _requireAuthenticatedSession(ref);
  return ref.watch(legalGoRepositoryProvider).fetchClientPayments();
});

final notificationsProvider = FutureProvider.autoDispose
    .family<List<LegalGoNotification>, bool>((ref, admin) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchNotifications(admin: admin);
    });

final profileProvider = FutureProvider.autoDispose<LegalGoUser>((ref) {
  _requireAuthenticatedSession(ref);
  return ref.watch(legalGoRepositoryProvider).fetchMe();
});

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  _requireAuthenticatedSession(ref);
  return ref.watch(legalGoRepositoryProvider).fetchAdminStats();
});

final adminDashboardProvider = FutureProvider.autoDispose
    .family<AdminDashboardStats, String>((ref, period) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchAdminDashboard(period: period);
    });

class AdminUsersQuery {
  const AdminUsersQuery({
    this.search,
    this.role = 'client',
    this.status,
    this.profileType,
    this.page = 1,
    this.limit = 20,
  });

  final String? search;
  final String role;
  final String? status;
  final String? profileType;
  final int page;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is AdminUsersQuery &&
        other.search == search &&
        other.role == role &&
        other.status == status &&
        other.profileType == profileType &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(search, role, status, profileType, page, limit);
}

final adminUsersProvider = FutureProvider.autoDispose
    .family<PaginatedResult<LegalGoUser>, AdminUsersQuery>((ref, query) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchAdminUsers(
            search: query.search,
            role: query.role,
            status: query.status,
            profileType: query.profileType,
            page: query.page,
            limit: query.limit,
          );
    });

class AdminRequestsQuery {
  const AdminRequestsQuery({
    this.search,
    this.serviceId,
    this.status,
    this.paymentStatus,
    this.page = 1,
    this.limit = 20,
  });

  final String? search;
  final String? serviceId;
  final String? status;
  final String? paymentStatus;
  final int page;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is AdminRequestsQuery &&
        other.search == search &&
        other.serviceId == serviceId &&
        other.status == status &&
        other.paymentStatus == paymentStatus &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(search, serviceId, status, paymentStatus, page, limit);
}

final adminRequestsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<LegalRequest>, AdminRequestsQuery>((ref, query) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchAdminRequests(
            search: query.search,
            serviceId: query.serviceId,
            status: query.status,
            paymentStatus: query.paymentStatus,
            page: query.page,
            limit: query.limit,
          );
    });

class AdminPaymentsQuery {
  const AdminPaymentsQuery({
    this.search,
    this.status,
    this.serviceId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 20,
  });

  final String? search;
  final String? status;
  final String? serviceId;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is AdminPaymentsQuery &&
        other.search == search &&
        other.status == status &&
        other.serviceId == serviceId &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(search, status, serviceId, dateFrom, dateTo, page, limit);
}

final adminPaymentsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Payment>, AdminPaymentsQuery>((ref, query) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchAdminPayments(
            search: query.search,
            status: query.status,
            serviceId: query.serviceId,
            dateFrom: query.dateFrom,
            dateTo: query.dateTo,
            page: query.page,
            limit: query.limit,
          );
    });

class AdminSubscriptionsQuery {
  const AdminSubscriptionsQuery({this.plan, this.status});

  final String? plan;
  final String? status;

  @override
  bool operator ==(Object other) {
    return other is AdminSubscriptionsQuery &&
        other.plan == plan &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(plan, status);
}

final adminSubscriptionsProvider = FutureProvider.autoDispose
    .family<List<DomiciliationSubscription>, AdminSubscriptionsQuery>((
      ref,
      query,
    ) {
      _requireAuthenticatedSession(ref);
      return ref
          .watch(legalGoRepositoryProvider)
          .fetchAdminSubscriptions(plan: query.plan, status: query.status);
    });

final adminLegalServicesProvider =
    FutureProvider.autoDispose<List<LegalServiceSummary>>((ref) {
      _requireAuthenticatedSession(ref);
      return ref.watch(legalGoRepositoryProvider).fetchAdminLegalServices();
    });
