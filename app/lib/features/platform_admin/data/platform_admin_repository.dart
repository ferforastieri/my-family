import 'package:dio/dio.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../data/models.dart';

class PlatformAdminRepository {
  const PlatformAdminRepository(this.auth);

  final AuthController auth;

  Future<PlatformOverview> overview() async {
    final response = await auth.dio.getUri<Map<String, dynamic>>(
      AppConfig.apiUri('/platform/admin/overview'),
    );
    return PlatformOverview.fromJson(_unwrap(response));
  }

  Future<PlatformAuditPage> audit({int page = 1, int limit = 30}) async {
    final response = await auth.dio.getUri<Map<String, dynamic>>(
      AppConfig.apiUri('/platform/admin/audit').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'},
      ),
    );
    return PlatformAuditPage.fromJson(_unwrap(response));
  }

  Future<List<SubscriptionPlan>> plans() async {
    final response = await auth.dio.getUri<Map<String, dynamic>>(
      AppConfig.apiUri('/platform/admin/plans'),
    );
    final data = _unwrap(response);
    return ((data['plans'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) =>
            SubscriptionPlan.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<SubscriptionPlan> updatePlan(
    String interval, {
    required String name,
    required String description,
    required int priceCents,
    required String currency,
    required String? stripePriceId,
    required bool active,
    required bool highlighted,
    required int sortOrder,
  }) async {
    final response = await auth.dio.patchUri<Map<String, dynamic>>(
      AppConfig.apiUri('/platform/admin/plans/$interval'),
      data: {
        'name': name,
        'description': description,
        'priceCents': priceCents,
        'currency': currency,
        'stripePriceId': stripePriceId,
        'active': active,
        'highlighted': highlighted,
        'sortOrder': sortOrder,
      },
    );
    return SubscriptionPlan.fromJson(_unwrap(response));
  }

  Future<PlatformLegalDocument?> privacyPolicy(String locale) async {
    final response = await auth.dio.getUri<Map<String, dynamic>>(
      AppConfig.apiUri('/platform/admin/legal/privacy-policy/$locale'),
    );
    final data = _unwrapNullable(response);
    return data == null ? null : PlatformLegalDocument.fromJson(data);
  }

  Future<PlatformLegalDocument> updatePrivacyPolicy(
    String locale, {
    required String title,
    required String body,
    required String format,
    required bool published,
    String? effectiveDate,
  }) async {
    final response = await auth.dio.patchUri<Map<String, dynamic>>(
      AppConfig.apiUri('/platform/admin/legal/privacy-policy/$locale'),
      data: {
        'title': title,
        'body': body,
        'format': format,
        'published': published,
        if (effectiveDate?.trim().isNotEmpty == true)
          'effectiveDate': effectiveDate!.trim(),
      },
    );
    return PlatformLegalDocument.fromJson(_unwrap(response));
  }

  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> response) {
    final body = response.data ?? const {};
    final data = body['data'];
    return data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(body);
  }

  Map<String, dynamic>? _unwrapNullable(
    Response<Map<String, dynamic>> response,
  ) {
    final body = response.data ?? const {};
    final data = body['data'];
    if (data == null) return null;
    return data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(body);
  }
}

class PlatformOverview {
  const PlatformOverview({
    required this.metrics,
    required this.tenantStatuses,
    required this.plans,
    required this.legalDocuments,
    required this.recentTenants,
    required this.recentAudit,
  });

  final PlatformMetrics metrics;
  final Map<String, int> tenantStatuses;
  final List<SubscriptionPlan> plans;
  final List<PlatformLegalDocument> legalDocuments;
  final List<PlatformTenantSummary> recentTenants;
  final List<PlatformAuditEntry> recentAudit;

  factory PlatformOverview.fromJson(Map<String, dynamic> json) {
    final statuses = Map<String, dynamic>.from(
      (json['tenantStatuses'] as Map?) ?? const {},
    );
    return PlatformOverview(
      metrics: PlatformMetrics.fromJson(
        Map<String, dynamic>.from((json['metrics'] as Map?) ?? const {}),
      ),
      tenantStatuses: statuses.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
      plans: ((json['plans'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              SubscriptionPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      legalDocuments: ((json['legalDocuments'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              PlatformLegalDocument.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      recentTenants: ((json['recentTenants'] as List?) ?? const [])
          .map((item) => PlatformTenantSummary.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      recentAudit: ((json['recentAudit'] as List?) ?? const [])
          .map((item) => PlatformAuditEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class PlatformLegalDocument {
  const PlatformLegalDocument({
    required this.id,
    required this.kind,
    required this.locale,
    required this.title,
    required this.body,
    required this.format,
    required this.updatedAt,
    this.effectiveDate,
    this.published = true,
  });

  final String id;
  final String kind;
  final String locale;
  final String title;
  final String body;
  final String format;
  final bool published;
  final DateTime? effectiveDate;
  final DateTime updatedAt;

  factory PlatformLegalDocument.fromJson(Map<String, dynamic> json) =>
      PlatformLegalDocument(
        id: json['id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'privacy-policy',
        locale: json['locale']?.toString() ?? 'pt',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        format: json['format']?.toString() ?? 'markdown',
        published: json['published'] != false,
        effectiveDate: DateTime.tryParse(
          json['effectiveDate']?.toString() ?? '',
        ),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PlatformMetrics {
  const PlatformMetrics({
    required this.totalUsers,
    required this.totalTenants,
    required this.activeTenants,
    required this.pendingTenants,
    required this.activeSubscriptions,
    required this.newUsers30d,
    required this.newTenants30d,
    required this.auditEvents24h,
  });

  final int totalUsers;
  final int totalTenants;
  final int activeTenants;
  final int pendingTenants;
  final int activeSubscriptions;
  final int newUsers30d;
  final int newTenants30d;
  final int auditEvents24h;

  factory PlatformMetrics.fromJson(Map<String, dynamic> json) =>
      PlatformMetrics(
        totalUsers: _integer(json['totalUsers']),
        totalTenants: _integer(json['totalTenants']),
        activeTenants: _integer(json['activeTenants']),
        pendingTenants: _integer(json['pendingTenants']),
        activeSubscriptions: _integer(json['activeSubscriptions']),
        newUsers30d: _integer(json['newUsers30d']),
        newTenants30d: _integer(json['newTenants30d']),
        auditEvents24h: _integer(json['auditEvents24h']),
      );
}

class PlatformTenantSummary {
  const PlatformTenantSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.isPublished,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String status;
  final bool isPublished;
  final DateTime createdAt;

  factory PlatformTenantSummary.fromJson(Map<String, dynamic> json) =>
      PlatformTenantSummary(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        status: json['status']?.toString() ?? 'draft',
        isPublished: json['isPublished'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PlatformAuditPage {
  const PlatformAuditPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });

  final List<PlatformAuditEntry> items;
  final int page;
  final int pages;
  final int total;

  factory PlatformAuditPage.fromJson(Map<String, dynamic> json) =>
      PlatformAuditPage(
        items: ((json['items'] as List?) ?? const [])
            .map((item) => PlatformAuditEntry.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
        page: _integer(json['page']),
        pages: _integer(json['pages']),
        total: _integer(json['total']),
      );
}

class PlatformAuditEntry {
  const PlatformAuditEntry({
    required this.id,
    required this.action,
    required this.resource,
    required this.source,
    required this.success,
    required this.createdAt,
    this.actorEmail,
    this.tenantId,
    this.path,
    this.statusCode,
    this.ip,
  });

  final String id;
  final String action;
  final String resource;
  final String source;
  final bool success;
  final DateTime createdAt;
  final String? actorEmail;
  final String? tenantId;
  final String? path;
  final int? statusCode;
  final String? ip;

  factory PlatformAuditEntry.fromJson(Map<String, dynamic> json) =>
      PlatformAuditEntry(
        id: json['id'].toString(),
        action: json['action']?.toString() ?? '',
        resource: json['resource']?.toString() ?? '',
        source: json['source']?.toString() ?? '',
        success: json['success'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        actorEmail: json['actorEmail']?.toString(),
        tenantId: json['tenantId']?.toString(),
        path: json['path']?.toString(),
        statusCode: (json['statusCode'] as num?)?.toInt(),
        ip: json['ip']?.toString(),
      );
}

int _integer(Object? value) => (value as num?)?.toInt() ?? 0;
