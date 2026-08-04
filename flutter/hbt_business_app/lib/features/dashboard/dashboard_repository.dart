/// Dashboard data layer — fetches the owner dashboard snapshot from the
/// real backend endpoint. No demo/seed data lives here.
library;

import '../../shared/services/api_client.dart';
import 'dashboard_models.dart';

/// Fetches dashboard snapshots from the backend.
abstract class DashboardRepository {
  Future<DashboardSnapshot> fetch({
    required String organizationId,
    required DashboardPeriod period,
  });
}

/// Production repository backed by the owner-dashboard endpoint
/// (`GET /organizations/{id}/reports/owner-dashboard/?period=…`).
class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<DashboardSnapshot> fetch({
    required String organizationId,
    required DashboardPeriod period,
  }) async {
    final path =
        '/organizations/$organizationId/reports/owner-dashboard/'
        '?period=${period.apiValue}';
    final json = await _api.get(path);
    return DashboardSnapshot.fromJson(json);
  }
}
