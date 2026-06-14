// ignore_for_file: prefer_null_aware_operators

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory PaginatedResult.fromJson(
    Object? json,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final map = asJsonMap(json);
    return PaginatedResult<T>(
      items: asJsonList(map['items']).map(fromJson).toList(),
      total: readInt(map['total']),
      page: readInt(map['page'], fallback: 1),
      limit: readInt(map['limit'], fallback: 20),
      totalPages: readInt(map['totalPages'], fallback: 1),
    );
  }
}

Map<String, dynamic> unwrapData(Object? json) {
  final map = asJsonMap(json);
  if (map.containsKey('data')) return asJsonMap(map['data']);
  return map;
}

List<Map<String, dynamic>> unwrapList(Object? json) {
  final data = json is Map<String, dynamic> && json.containsKey('data') ? json['data'] : json;
  return asJsonList(data);
}

Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asJsonList(Object? value) {
  if (value is List) return value.map(asJsonMap).toList();
  return const [];
}

String readId(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is num) return value.toInt().toString();
  return value.toString();
}

String? readNullableId(Object? value) {
  if (value == null) return null;
  final id = readId(value);
  return id.isEmpty ? null : id;
}

String readString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? readNullableString(Object? value) => value == null ? null : value.toString();

int readInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool readBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? readDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class LegalGoUser {
  const LegalGoUser({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.createdAt,
    this.requestsCount,
    this.profiles = const [],
  });

  final String id;
  final String email;
  final String? phone;
  final String role;
  final bool status;
  final DateTime? createdAt;
  final int? requestsCount;
  final List<UserProfile> profiles;

  factory LegalGoUser.fromJson(Map<String, dynamic> json) => LegalGoUser(
        id: readId(json['id']),
        email: readString(json['email']),
        phone: readNullableString(json['phone']),
        role: readString(json['role'], fallback: 'client'),
        status: readBool(json['status'], fallback: true),
        createdAt: readDate(json['createdAt'] ?? json['created_at']),
        requestsCount: json['requestsCount'] == null ? null : readInt(json['requestsCount']),
        profiles: asJsonList(json['profiles']).map(UserProfile.fromJson).toList(),
      );

  String get displayName {
    for (final profile in profiles) {
      final individual = profile.individualProfile;
      if (individual != null && '${individual.firstname} ${individual.lastname}'.trim().isNotEmpty) {
        return '${individual.firstname} ${individual.lastname}'.trim();
      }
      final company = profile.companyProfile;
      if (company != null && company.companyName.isNotEmpty) return company.companyName;
    }
    return email;
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.userId,
    required this.profileType,
    this.individualProfile,
    this.companyProfile,
  });

  final String id;
  final String userId;
  final String profileType;
  final IndividualProfile? individualProfile;
  final CompanyProfile? companyProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: readId(json['id']),
        userId: readId(json['userId'] ?? json['user_id']),
        profileType: readString(json['profileType'] ?? json['profile_type']),
        individualProfile: json['individualProfile'] == null ? null : IndividualProfile.fromJson(asJsonMap(json['individualProfile'])),
        companyProfile: json['companyProfile'] == null ? null : CompanyProfile.fromJson(asJsonMap(json['companyProfile'])),
      );
}

class IndividualProfile {
  const IndividualProfile({required this.id, this.civility, required this.firstname, required this.lastname});

  final String id;
  final String? civility;
  final String firstname;
  final String lastname;

  factory IndividualProfile.fromJson(Map<String, dynamic> json) => IndividualProfile(
        id: readId(json['id']),
        civility: readNullableString(json['civility']),
        firstname: readString(json['firstname']),
        lastname: readString(json['lastname']),
      );
}

class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.companyName,
    this.legalForm,
    this.siren,
    this.vatNumber,
    this.address,
    this.members = const [],
  });

  final String id;
  final String companyName;
  final String? legalForm;
  final String? siren;
  final String? vatNumber;
  final String? address;
  final List<CompanyMember> members;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        id: readId(json['id']),
        companyName: readString(json['companyName'] ?? json['company_name']),
        legalForm: readNullableString(json['legalForm'] ?? json['legal_form']),
        siren: readNullableString(json['siren']),
        vatNumber: readNullableString(json['vatNumber'] ?? json['vat_number']),
        address: readNullableString(json['address']),
        members: asJsonList(json['members']).map(CompanyMember.fromJson).toList(),
      );
}

class CompanyMember {
  const CompanyMember({required this.id, required this.fullname, required this.role, required this.percentage});

  final String id;
  final String fullname;
  final String role;
  final String percentage;

  factory CompanyMember.fromJson(Map<String, dynamic> json) => CompanyMember(
        id: readId(json['id']),
        fullname: readString(json['fullname']),
        role: readString(json['role']),
        percentage: readString(json['percentage'], fallback: '0'),
      );
}

class ServiceCategorySummary {
  const ServiceCategorySummary({required this.id, required this.title, required this.slug});

  final String id;
  final String title;
  final String slug;

  factory ServiceCategorySummary.fromJson(Map<String, dynamic> json) => ServiceCategorySummary(
        id: readId(json['id']),
        title: readString(json['title']),
        slug: readString(json['slug']),
      );
}

class LegalServiceSummary {
  const LegalServiceSummary({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.active,
    this.category,
    this.packs = const [],
    this.requiredDocuments = const [],
  });

  final String id;
  final String title;
  final String slug;
  final String? description;
  final bool active;
  final ServiceCategorySummary? category;
  final List<PackSummary> packs;
  final List<ServiceRequiredDocument> requiredDocuments;

  factory LegalServiceSummary.fromJson(Map<String, dynamic> json) => LegalServiceSummary(
        id: readId(json['id']),
        title: readString(json['title']),
        slug: readString(json['slug']),
        description: readNullableString(json['description']),
        active: readBool(json['active'], fallback: true),
        category: json['category'] == null ? null : ServiceCategorySummary.fromJson(asJsonMap(json['category'])),
        packs: asJsonList(json['packs']).map(PackSummary.fromJson).toList(),
        requiredDocuments: asJsonList(json['requiredDocuments']).map(ServiceRequiredDocument.fromJson).toList(),
      );
}

class PackSummary {
  const PackSummary({
    required this.id,
    this.serviceId,
    required this.title,
    this.description,
    required this.price,
    required this.delayDays,
    this.benefits = const [],
    required this.recommended,
    required this.active,
  });

  final String id;
  final String? serviceId;
  final String title;
  final String? description;
  final String price;
  final int delayDays;
  final List<String> benefits;
  final bool recommended;
  final bool active;

  factory PackSummary.fromJson(Map<String, dynamic> json) => PackSummary(
        id: readId(json['id']),
        serviceId: readNullableId(json['serviceId'] ?? json['service_id']),
        title: readString(json['title']),
        description: readNullableString(json['description']),
        price: readString(json['price'], fallback: '0.00'),
        delayDays: readInt(json['delayDays'] ?? json['delay_days']),
        benefits: (json['benefits'] is List) ? (json['benefits'] as List).map((item) => item.toString()).toList() : const [],
        recommended: readBool(json['recommended']),
        active: readBool(json['active'], fallback: true),
      );
}

class ServiceRequiredDocument {
  const ServiceRequiredDocument({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.category,
    this.description,
    required this.isRequired,
    required this.active,
  });

  final String id;
  final String serviceId;
  final String title;
  final String category;
  final String? description;
  final bool isRequired;
  final bool active;

  factory ServiceRequiredDocument.fromJson(Map<String, dynamic> json) => ServiceRequiredDocument(
        id: readId(json['id']),
        serviceId: readId(json['serviceId'] ?? json['service_id']),
        title: readString(json['title']),
        category: readString(json['category']),
        description: readNullableString(json['description']),
        isRequired: readBool(json['isRequired'] ?? json['is_required'], fallback: true),
        active: readBool(json['active'], fallback: true),
      );
}

class LegalRequest {
  const LegalRequest({
    required this.id,
    required this.reference,
    required this.status,
    required this.paymentStatus,
    required this.currentStep,
    required this.totalPrice,
    this.customerEmail,
    this.customerPhone,
    this.customerFirstname,
    this.customerLastname,
    this.user,
    this.service,
    this.pack,
    this.answers = const [],
    this.payments = const [],
    this.documents = const [],
    this.statusHistory = const [],
    this.domiciliationSubscription,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reference;
  final String status;
  final String paymentStatus;
  final int currentStep;
  final String totalPrice;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerFirstname;
  final String? customerLastname;
  final LegalGoUser? user;
  final LegalServiceSummary? service;
  final PackSummary? pack;
  final List<RequestAnswer> answers;
  final List<Payment> payments;
  final List<LegalDocument> documents;
  final List<RequestStatusHistory> statusHistory;
  final DomiciliationSubscription? domiciliationSubscription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LegalRequest.fromJson(Map<String, dynamic> json, {bool shallow = false}) => LegalRequest(
        id: readId(json['id']),
        reference: readString(json['reference']),
        status: readString(json['status']),
        paymentStatus: readString(json['paymentStatus'] ?? json['payment_status']),
        currentStep: readInt(json['currentStep'] ?? json['current_step']),
        totalPrice: readString(json['totalPrice'] ?? json['total_price'], fallback: '0.00'),
        customerEmail: readNullableString(json['customerEmail'] ?? json['customer_email']),
        customerPhone: readNullableString(json['customerPhone'] ?? json['customer_phone']),
        customerFirstname: readNullableString(json['customerFirstname'] ?? json['customer_firstname']),
        customerLastname: readNullableString(json['customerLastname'] ?? json['customer_lastname']),
        user: shallow || json['user'] == null ? null : LegalGoUser.fromJson(asJsonMap(json['user'])),
        service: json['service'] == null ? null : LegalServiceSummary.fromJson(asJsonMap(json['service'])),
        pack: json['pack'] == null ? null : PackSummary.fromJson(asJsonMap(json['pack'])),
        answers: shallow ? const [] : asJsonList(json['answers']).map(RequestAnswer.fromJson).toList(),
        payments: shallow ? const [] : asJsonList(json['payments']).map(Payment.fromJson).toList(),
        documents: shallow ? const [] : asJsonList(json['documents']).map(LegalDocument.fromJson).toList(),
        statusHistory: shallow ? const [] : asJsonList(json['statusHistory']).map(RequestStatusHistory.fromJson).toList(),
        domiciliationSubscription: shallow || json['domiciliationSubscription'] == null
            ? null
            : DomiciliationSubscription.fromJson(asJsonMap(json['domiciliationSubscription'])),
        createdAt: readDate(json['createdAt'] ?? json['created_at']),
        updatedAt: readDate(json['updatedAt'] ?? json['updated_at']),
      );

  String get customerName => [customerFirstname, customerLastname].whereType<String>().where((part) => part.isNotEmpty).join(' ');
}

class RequestAnswer {
  const RequestAnswer({required this.id, required this.fieldName, this.fieldValue});

  final String id;
  final String fieldName;
  final String? fieldValue;

  factory RequestAnswer.fromJson(Map<String, dynamic> json) => RequestAnswer(
        id: readId(json['id']),
        fieldName: readString(json['fieldName'] ?? json['field_name']),
        fieldValue: readNullableString(json['fieldValue'] ?? json['field_value']),
      );
}

class RequestStatusHistory {
  const RequestStatusHistory({required this.id, this.oldStatus, required this.newStatus, this.reason, this.createdAt});

  final String id;
  final String? oldStatus;
  final String newStatus;
  final String? reason;
  final DateTime? createdAt;

  factory RequestStatusHistory.fromJson(Map<String, dynamic> json) => RequestStatusHistory(
        id: readId(json['id']),
        oldStatus: readNullableString(json['oldStatus'] ?? json['old_status']),
        newStatus: readString(json['newStatus'] ?? json['new_status']),
        reason: readNullableString(json['reason']),
        createdAt: readDate(json['createdAt'] ?? json['created_at']),
      );
}

class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.requestId,
    required this.title,
    this.file,
    this.originalName,
    this.mimeType,
    this.sizeBytes,
    required this.type,
    required this.status,
    this.rejectionReason,
    this.requestedMessage,
    required this.requestedByAdmin,
    this.serviceRequiredDocumentId,
    this.requiredDocument,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String requestId;
  final String title;
  final String? file;
  final String? originalName;
  final String? mimeType;
  final int? sizeBytes;
  final String type;
  final String status;
  final String? rejectionReason;
  final String? requestedMessage;
  final bool requestedByAdmin;
  final String? serviceRequiredDocumentId;
  final ServiceRequiredDocument? requiredDocument;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
        id: readId(json['id']),
        requestId: readId(json['requestId'] ?? json['request_id']),
        title: readString(json['title']),
        file: readNullableString(json['file']),
        originalName: readNullableString(json['originalName'] ?? json['original_name']),
        mimeType: readNullableString(json['mimeType'] ?? json['mime_type']),
        sizeBytes: json['sizeBytes'] == null && json['size_bytes'] == null ? null : readInt(json['sizeBytes'] ?? json['size_bytes']),
        type: readString(json['type']),
        status: readString(json['status']),
        rejectionReason: readNullableString(json['rejectionReason'] ?? json['rejection_reason']),
        requestedMessage: readNullableString(json['requestedMessage'] ?? json['requested_message']),
        requestedByAdmin: readBool(json['requestedByAdmin'] ?? json['requested_by_admin']),
        serviceRequiredDocumentId: readNullableId(json['serviceRequiredDocumentId'] ?? json['service_required_document_id']),
        requiredDocument: json['requiredDocument'] == null ? null : ServiceRequiredDocument.fromJson(asJsonMap(json['requiredDocument'])),
        createdAt: readDate(json['createdAt'] ?? json['created_at']),
        updatedAt: readDate(json['updatedAt'] ?? json['updated_at']),
      );

  bool get canDownload => file != null && file!.isNotEmpty;
  String get downloadName => originalName?.isNotEmpty == true ? originalName! : '$title-$id';
}

class RequestDocumentsPayload {
  const RequestDocumentsPayload({required this.requiredDocuments, required this.documents});

  final List<ServiceRequiredDocument> requiredDocuments;
  final List<LegalDocument> documents;

  factory RequestDocumentsPayload.fromJson(Object? json) {
    final map = asJsonMap(json);
    return RequestDocumentsPayload(
      requiredDocuments: asJsonList(map['requiredDocuments']).map(ServiceRequiredDocument.fromJson).toList(),
      documents: asJsonList(map['documents']).map(LegalDocument.fromJson).toList(),
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    this.requestId,
    required this.amount,
    required this.status,
    this.stripeSessionId,
    this.paymentDate,
    this.request,
  });

  final String id;
  final String? requestId;
  final String amount;
  final String status;
  final String? stripeSessionId;
  final DateTime? paymentDate;
  final LegalRequest? request;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: readId(json['id']),
        requestId: readNullableId(json['requestId'] ?? json['request_id']),
        amount: readString(json['amount'], fallback: '0.00'),
        status: readString(json['status']),
        stripeSessionId: readNullableString(json['stripeSessionId'] ?? json['stripe_session_id']),
        paymentDate: readDate(json['paymentDate'] ?? json['payment_date']),
        request: json['request'] == null ? null : LegalRequest.fromJson(asJsonMap(json['request']), shallow: true),
      );
}

class DomiciliationPlan {
  const DomiciliationPlan({required this.id, required this.key, required this.title, required this.amount, required this.durationMonths});

  final String id;
  final String key;
  final String title;
  final String amount;
  final int durationMonths;

  factory DomiciliationPlan.fromJson(Map<String, dynamic> json) => DomiciliationPlan(
        id: readId(json['id']),
        key: readString(json['key']),
        title: readString(json['title']),
        amount: readString(json['amount'], fallback: '0.00'),
        durationMonths: readInt(json['durationMonths'] ?? json['duration_months']),
      );
}

class SubscriptionPayment {
  const SubscriptionPayment({required this.id, required this.amount, required this.status, this.paidAt});

  final String id;
  final String amount;
  final String status;
  final DateTime? paidAt;

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) => SubscriptionPayment(
        id: readId(json['id']),
        amount: readString(json['amount'], fallback: '0.00'),
        status: readString(json['status']),
        paidAt: readDate(json['paidAt'] ?? json['paid_at']),
      );
}

class DomiciliationSubscription {
  const DomiciliationSubscription({
    required this.id,
    required this.formula,
    this.amount,
    required this.monthlyPrice,
    this.plan,
    this.startDate,
    this.endDate,
    this.expiresAt,
    required this.renewalDate,
    required this.status,
    this.user,
    this.request,
    this.payments = const [],
  });

  final String id;
  final String formula;
  final String? amount;
  final String monthlyPrice;
  final DomiciliationPlan? plan;
  final String? startDate;
  final String? endDate;
  final String? expiresAt;
  final String renewalDate;
  final String status;
  final LegalGoUser? user;
  final LegalRequest? request;
  final List<SubscriptionPayment> payments;

  factory DomiciliationSubscription.fromJson(Map<String, dynamic> json) => DomiciliationSubscription(
        id: readId(json['id']),
        formula: readString(json['formula']),
        amount: readNullableString(json['amount']),
        monthlyPrice: readString(json['monthlyPrice'] ?? json['monthly_price'], fallback: '0.00'),
        plan: json['plan'] == null ? null : DomiciliationPlan.fromJson(asJsonMap(json['plan'])),
        startDate: readNullableString(json['startDate'] ?? json['start_date']),
        endDate: readNullableString(json['endDate'] ?? json['end_date']),
        expiresAt: readNullableString(json['expiresAt'] ?? json['expires_at']),
        renewalDate: readString(json['renewalDate'] ?? json['renewal_date']),
        status: readString(json['status']),
        user: json['user'] == null ? null : LegalGoUser.fromJson(asJsonMap(json['user'])),
        request: json['request'] == null ? null : LegalRequest.fromJson(asJsonMap(json['request']), shallow: true),
        payments: asJsonList(json['payments']).map(SubscriptionPayment.fromJson).toList(),
      );

  String get displayAmount => plan?.amount ?? amount ?? monthlyPrice;
  String get expiration => expiresAt ?? endDate ?? renewalDate;
}

class AdminStats {
  const AdminStats({required this.users, required this.requests, required this.subscriptions, required this.paidRevenue});

  final int users;
  final int requests;
  final int subscriptions;
  final String paidRevenue;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        users: readInt(json['users']),
        requests: readInt(json['requests']),
        subscriptions: readInt(json['subscriptions']),
        paidRevenue: readString(json['paidRevenue'], fallback: '0.00'),
      );
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.summary,
    required this.requestsEvolution,
    required this.servicesDistribution,
    required this.domiciliationStats,
    required this.alerts,
  });

  final AdminStats summary;
  final List<DashboardBucket> requestsEvolution;
  final List<ServiceDistribution> servicesDistribution;
  final DomiciliationStats domiciliationStats;
  final DashboardAlerts alerts;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) => AdminDashboardStats(
        summary: AdminStats.fromJson(asJsonMap(json['summary'])),
        requestsEvolution: asJsonList(json['requestsEvolution']).map(DashboardBucket.fromJson).toList(),
        servicesDistribution: asJsonList(json['servicesDistribution']).map(ServiceDistribution.fromJson).toList(),
        domiciliationStats: DomiciliationStats.fromJson(asJsonMap(json['domiciliationStats'])),
        alerts: DashboardAlerts.fromJson(asJsonMap(json['alerts'])),
      );
}

class DashboardBucket {
  const DashboardBucket({required this.label, required this.date, required this.count});

  final String label;
  final String date;
  final int count;

  factory DashboardBucket.fromJson(Map<String, dynamic> json) => DashboardBucket(
        label: readString(json['label']),
        date: readString(json['date']),
        count: readInt(json['count']),
      );
}

class ServiceDistribution {
  const ServiceDistribution({required this.label, required this.count, required this.percentage});

  final String label;
  final int count;
  final num percentage;

  factory ServiceDistribution.fromJson(Map<String, dynamic> json) => ServiceDistribution(
        label: readString(json['label']),
        count: readInt(json['count']),
        percentage: json['percentage'] is num ? json['percentage'] as num : num.tryParse(readString(json['percentage'])) ?? 0,
      );
}

class DomiciliationStats {
  const DomiciliationStats({
    required this.active,
    required this.expired,
    required this.renewingSoon,
    required this.generatedAmount,
    required this.formulas,
  });

  final int active;
  final int expired;
  final int renewingSoon;
  final num generatedAmount;
  final List<DomiciliationFormulaStat> formulas;

  factory DomiciliationStats.fromJson(Map<String, dynamic> json) => DomiciliationStats(
        active: readInt(json['active']),
        expired: readInt(json['expired']),
        renewingSoon: readInt(json['renewingSoon']),
        generatedAmount: json['generatedAmount'] is num ? json['generatedAmount'] as num : num.tryParse(readString(json['generatedAmount'])) ?? 0,
        formulas: asJsonList(json['formulas']).map(DomiciliationFormulaStat.fromJson).toList(),
      );
}

class DomiciliationFormulaStat {
  const DomiciliationFormulaStat({required this.formula, required this.count, required this.amount, required this.percentage});

  final String formula;
  final int count;
  final num amount;
  final num percentage;

  factory DomiciliationFormulaStat.fromJson(Map<String, dynamic> json) => DomiciliationFormulaStat(
        formula: readString(json['formula']),
        count: readInt(json['count']),
        amount: json['amount'] is num ? json['amount'] as num : num.tryParse(readString(json['amount'])) ?? 0,
        percentage: json['percentage'] is num ? json['percentage'] as num : num.tryParse(readString(json['percentage'])) ?? 0,
      );
}

class DashboardAlerts {
  const DashboardAlerts({
    required this.failedPayments,
    required this.pendingPayments,
    required this.expiringSubscriptions,
    required this.untreatedRequests,
    required this.pendingPaymentRequests,
  });

  final int failedPayments;
  final int pendingPayments;
  final int expiringSubscriptions;
  final int untreatedRequests;
  final int pendingPaymentRequests;

  factory DashboardAlerts.fromJson(Map<String, dynamic> json) => DashboardAlerts(
        failedPayments: readInt(json['failedPayments']),
        pendingPayments: readInt(json['pendingPayments']),
        expiringSubscriptions: readInt(json['expiringSubscriptions']),
        untreatedRequests: readInt(json['untreatedRequests']),
        pendingPaymentRequests: readInt(json['pendingPaymentRequests']),
      );
}

