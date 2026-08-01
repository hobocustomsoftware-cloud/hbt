import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/shared/services/refund_service.dart';

/// Mock tracking call order for the full refund lifecycle.
class RefundFullFlowMockApi extends ApiClient {
  RefundFullFlowMockApi() : super(baseUrl: 'https://example.com');

  final _getResults = <String, Map<String, dynamic>>{};
  final _getListResults = <String, List<dynamic>>{};
  final _postResults = <String, Map<String, dynamic>>{};

  final callLog = <String>[];

  void returnsGet(String path, Map<String, dynamic> result) =>
      _getResults[path] = result;
  void returnsGetList(String path, List<dynamic> result) =>
      _getListResults[path] = result;
  void returnsPost(String path, Map<String, dynamic> result) =>
      _postResults[path] = result;

  @override
  Future<Map<String, dynamic>> get(String path) async {
    callLog.add('GET $path');
    final result = _getResults[path];
    if (result != null) return result;
    throw ApiException('Not found: $path');
  }

  @override
  Future<List<dynamic>> getList(String path) async {
    callLog.add('GET LIST $path');
    final result = _getListResults[path];
    if (result != null) return result;
    throw ApiException('Not found: $path');
  }

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    callLog.add('POST $path');
    final result = _postResults[path];
    if (result != null) return result;
    throw ApiException('Not found: $path');
  }
}

void main() {
  group('Refund Integration — full lifecycle', () {
    late RefundFullFlowMockApi api;
    late RefundService service;
    const orgId = 'org-001';

    setUp(() {
      api = RefundFullFlowMockApi();
      service = RefundService.forTest(api: api, orgId: orgId);
    });

    test('full refund lifecycle: request → approve → paid → complete', () async {
      const refundId = 'rf-1';
      const paymentId = 'pay-1';

      // Step 1: Request refund
      api.returnsPost('/organizations/$orgId/refunds/', {
        'id': refundId,
        'payment': paymentId,
        'refund_number': 'RF-001',
        'requested_amount': '50000',
        'approved_amount': null,
        'status': 'requested',
        'reason': 'Customer cancellation',
      });
      final requested = await service.request(
        paymentId: paymentId,
        requestedAmount: 50000,
        reason: 'Customer cancellation',
      );
      expect(requested['id'], refundId);
      expect(requested['status'], 'requested');
      expect(requested['approved_amount'], isNull);

      // Step 2: Approve refund
      api.returnsPost('/organizations/$orgId/refunds/$refundId/decision/', {
        'id': refundId,
        'status': 'approved',
        'approved_amount': '45000',
        'decision_reason': 'Approved with 10% processing fee',
      });
      final approved = await service.decide(
        refundId: refundId,
        approve: true,
        approvedAmount: 45000,
        reason: 'Approved with 10% processing fee',
      );
      expect(approved['status'], 'approved');
      expect(approved['approved_amount'], '45000');

      // Step 3: Mark as paid
      api.returnsPost('/organizations/$orgId/refunds/$refundId/paid/', {
        'id': refundId,
        'status': 'paid',
      });
      final paid = await service.markPaid(
        refundId: refundId,
        payoutReference: 'TRF-45000',
      );
      expect(paid['status'], 'paid');

      // Step 4: Complete
      api.returnsPost('/organizations/$orgId/refunds/$refundId/complete/', {
        'id': refundId,
        'status': 'completed',
      });
      final completed = await service.complete(refundId);
      expect(completed['status'], 'completed');

      // Verify call order
      expect(api.callLog.length, 4);
      expect(api.callLog[0], 'POST /organizations/$orgId/refunds/');
      expect(api.callLog[1],
          'POST /organizations/$orgId/refunds/$refundId/decision/');
      expect(api.callLog[2],
          'POST /organizations/$orgId/refunds/$refundId/paid/');
      expect(api.callLog[3],
          'POST /organizations/$orgId/refunds/$refundId/complete/');
    });

    test('refund rejection: request → reject', () async {
      const refundId = 'rf-2';
      const paymentId = 'pay-2';

      api.returnsPost('/organizations/$orgId/refunds/', {
        'id': refundId,
        'payment': paymentId,
        'refund_number': 'RF-002',
        'status': 'requested',
        'requested_amount': '30000',
        'reason': 'Overcharged',
      });
      final requested = await service.request(
        paymentId: paymentId,
        requestedAmount: 30000,
        reason: 'Overcharged',
      );
      expect(requested['status'], 'requested');

      api.returnsPost('/organizations/$orgId/refunds/$refundId/decision/', {
        'id': refundId,
        'status': 'rejected',
        'decision_reason': 'Policy violation',
      });
      final rejected = await service.decide(
        refundId: refundId,
        approve: false,
        reason: 'Policy violation',
      );
      expect(rejected['status'], 'rejected');

      expect(api.callLog.length, 2);
    });

    test('refund with ticket: includes ticket reference', () async {
      const refundId = 'rf-3';

      api.returnsPost('/organizations/$orgId/refunds/', {
        'id': refundId,
        'ticket': 'tkt-1',
        'status': 'requested',
      });
      final result = await service.request(
        paymentId: 'pay-3',
        requestedAmount: 25000,
        reason: 'Partial refund',
        ticketId: 'tkt-1',
      );
      expect(result['ticket'], 'tkt-1');
    });

    test('list refunds and get single refund', () async {
      // Setup: list returns results
      api.returnsGetList('/organizations/$orgId/refunds/', [
        {'id': 'rf-1', 'refund_number': 'RF-001', 'status': 'paid'},
        {'id': 'rf-2', 'refund_number': 'RF-002', 'status': 'requested'},
        {'id': 'rf-3', 'refund_number': 'RF-003', 'status': 'completed'},
      ]);

      // List
      final list = await service.list();
      expect(list.length, 3);
      expect(list.first['refund_number'], 'RF-001');

      // Single get
      api.returnsGet('/organizations/$orgId/refunds/rf-1/', {
        'id': 'rf-1',
        'refund_number': 'RF-001',
        'status': 'paid',
        'requested_amount': '50000',
      });
      final detail = await service.get('rf-1');
      expect(detail['status'], 'paid');
      expect(detail['requested_amount'], '50000');
    });

    test('list with status filter', () async {
      api.returnsGetList(
          '/organizations/$orgId/refunds/?status=paid', [
        {'id': 'rf-1', 'status': 'paid'},
      ]);
      final filtered = await service.list(status: 'paid');
      expect(filtered.length, 1);
      expect(filtered.first['status'], 'paid');
    });
  });
}
