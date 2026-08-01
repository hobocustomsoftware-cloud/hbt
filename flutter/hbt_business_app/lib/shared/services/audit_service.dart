import '../../shared/services/api_client.dart';

/// Records audit log entries for operations performed at a counter.
///
/// Each entry captures: counter ID, user ID, device ID, timestamp,
/// action, resource type, resource ID, and optional detail payload.
/// Entries are sent to the server immediately (fire-and-forget).
///
/// The [deviceId] parameter is the installation UUID from [DeviceRegistry].
class AuditService {
  AuditService({
    required ApiClient api,
    required String organizationId,
    this.deviceId,
  })  : _api = api,
        _orgId = organizationId;

  final ApiClient _api;
  final String _orgId;
  final String? deviceId;

  /// Record an audit entry.
  ///
  /// Returns `true` if the entry was sent successfully, `false` on
  /// network error (entry is silently dropped — no retry queue).
  Future<bool> record({
    required String action,
    required String resourceType,
    required String resourceId,
    String? counterId,
    String? branchId,
    String? userId,
    String? shiftId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _api.post('/organizations/$_orgId/audit-logs/', {
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'counter_id': ?counterId,
        'branch_id': ?branchId,
        'user_id': ?userId,
        'device_id': ?deviceId,
        'shift_id': ?shiftId,
        'details': ?details,
      });
      return true;
    } on ApiException {
      return false;
    }
  }
}
