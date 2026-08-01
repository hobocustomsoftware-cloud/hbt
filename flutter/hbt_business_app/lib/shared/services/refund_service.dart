import 'api_client.dart';
import '../../features/auth/controllers/session_controller.dart';

/// Service wrapping all refund-related API calls.
class RefundService {
  RefundService({required SessionController session})
      : _api = session.api,
        _session = session,
        _orgIdForTest = null;

  /// Direct constructor for testing — bypasses [SessionController].
  RefundService.forTest({required ApiClient api, required String orgId})
      : _api = api,
        _session = null,
        _orgIdForTest = orgId;

  final ApiClient _api;
  final SessionController? _session;
  final String? _orgIdForTest;

  String get _orgId =>
      _orgIdForTest ?? _session!.activeOrganization?.organization.id ?? '';

  String get orgId => _orgId;

  // ── Refund Policy ────────────────────────────────────────────────

  /// Fetch the current refund policy for the active organization.
  Future<Map<String, dynamic>> getPolicy() async {
    final data = await _api.get('/organizations/$_orgId/refund-policy/');
    return data;
  }

  /// Update the refund policy (requires `refund.policy.manage`).
  Future<Map<String, dynamic>> updatePolicy({
    required bool enabled,
    required int refundWindowHours,
    required double refundPercentage,
    required double fixedFee,
    required double approvalThreshold,
  }) async {
    final data = await _api.put(
      '/organizations/$_orgId/refund-policy/',
      {
        'enabled': enabled,
        'refund_window_hours': refundWindowHours,
        'refund_percentage': refundPercentage.toString(),
        'fixed_fee': fixedFee.toString(),
        'approval_threshold': approvalThreshold.toString(),
      },
    );
    return data;
  }

  // ── Refund Requests ──────────────────────────────────────────────

  /// List all refund requests for the active organization.
  Future<List<Map<String, dynamic>>> list({String? status}) async {
    final path = status != null
        ? '/organizations/$_orgId/refunds/?status=$status'
        : '/organizations/$_orgId/refunds/';
    final data = await _api.getList(path);
    return data.cast<Map<String, dynamic>>();
  }

  /// Get a single refund request by ID.
  Future<Map<String, dynamic>> get(String refundId) async {
    final data = await _api.get('/organizations/$_orgId/refunds/$refundId/');
    return data;
  }

  /// Create a new refund request (requires `refund.request`).
  Future<Map<String, dynamic>> request({
    required String paymentId,
    required double requestedAmount,
    required String reason,
    String? ticketId,
  }) async {
    final body = <String, dynamic>{
      'payment': paymentId,
      'requested_amount': requestedAmount.toString(),
      'reason': reason,
    };
    if (ticketId != null) {
      body['ticket'] = ticketId;
    }
    final data = await _api.post(
      '/organizations/$_orgId/refunds/',
      body,
    );
    return data;
  }

  /// Approve or reject a refund (requires `refund.approve`).
  Future<Map<String, dynamic>> decide({
    required String refundId,
    required bool approve,
    double? approvedAmount,
    String reason = '',
  }) async {
    final body = <String, dynamic>{
      'approve': approve,
      'reason': reason,
    };
    if (approve && approvedAmount != null) {
      body['approved_amount'] = approvedAmount.toString();
    }
    final data = await _api.post(
      '/organizations/$_orgId/refunds/$refundId/decision/',
      body,
    );
    return data;
  }

  /// Mark an approved refund as paid (requires `refund.pay`).
  Future<Map<String, dynamic>> markPaid({
    required String refundId,
    required String payoutReference,
  }) async {
    final data = await _api.post(
      '/organizations/$_orgId/refunds/$refundId/paid/',
      {'payout_reference': payoutReference},
    );
    return data;
  }

  /// Complete a paid refund (requires `refund.complete`).
  Future<Map<String, dynamic>> complete(String refundId) async {
    final data = await _api.post(
      '/organizations/$_orgId/refunds/$refundId/complete/',
      {},
    );
    return data;
  }
}
