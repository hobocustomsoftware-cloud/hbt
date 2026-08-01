import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/shared/services/refund_service.dart';

/// Minimal mock extending [ApiClient] for testing [RefundService].
class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'https://example.com');

  final _getResults = <String, Map<String, dynamic>>{};
  final _getListResults = <String, List<dynamic>>{};
  final _postResults = <String, Map<String, dynamic>>{};

  void returnsGet(String path, Map<String, dynamic> result) =>
      _getResults[path] = result;
  void returnsGetList(String path, List<dynamic> result) =>
      _getListResults[path] = result;
  void returnsPost(String path, Map<String, dynamic> result) =>
      _postResults[path] = result;

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final result = _getResults[path];
    if (result != null) return result;
    throw ApiException('Not found');
  }

  @override
  Future<List<dynamic>> getList(String path) async {
    final result = _getListResults[path];
    if (result != null) return result;
    throw ApiException('Not found');
  }

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final result = _postResults[path];
    if (result != null) return result;
    throw ApiException('Not found');
  }
}

void main() {
  group('RefundService', () {
    late MockApiClient api;
    late RefundService service;

    setUp(() {
      api = MockApiClient();
      service = RefundService.forTest(api: api, orgId: 'org-001');
    });

    test('list calls getList with correct path', () async {
      api.returnsGetList('/organizations/org-001/refunds/', [
        {'id': 'r1'},
      ]);
      final result = await service.list();
      expect(result.length, 1);
      expect(result.first['id'], 'r1');
    });

    test('list with status filter appends query param', () async {
      api.returnsGetList(
          '/organizations/org-001/refunds/?status=requested', [
        {'id': 'r2'},
      ]);
      final result = await service.list(status: 'requested');
      expect(result.length, 1);
      expect(result.first['id'], 'r2');
    });

    test('get calls correct path', () async {
      api.returnsGet('/organizations/org-001/refunds/r1/', {
        'id': 'r1',
        'status': 'requested',
      });
      final result = await service.get('r1');
      expect(result['id'], 'r1');
      expect(result['status'], 'requested');
    });

    test('request posts to refunds endpoint', () async {
      api.returnsPost('/organizations/org-001/refunds/', {
        'id': 'r3',
        'status': 'requested',
      });
      final result = await service.request(
        paymentId: 'p1',
        requestedAmount: 50000,
        reason: 'Customer requested cancellation',
      );
      expect(result['id'], 'r3');
    });

    test('request with ticket includes ticket field', () async {
      api.returnsPost('/organizations/org-001/refunds/', {
        'id': 'r4',
        'ticket': 't1',
      });
      final result = await service.request(
        paymentId: 'p1',
        requestedAmount: 30000,
        reason: 'Partial refund',
        ticketId: 't1',
      );
      expect(result['ticket'], 't1');
    });

    test('decide approve posts to decision endpoint', () async {
      api.returnsPost('/organizations/org-001/refunds/r1/decision/', {
        'id': 'r1',
        'status': 'approved',
      });
      final result = await service.decide(
        refundId: 'r1',
        approve: true,
        approvedAmount: 45000,
      );
      expect(result['status'], 'approved');
    });

    test('decide reject posts to decision endpoint', () async {
      api.returnsPost('/organizations/org-001/refunds/r1/decision/', {
        'id': 'r1',
        'status': 'rejected',
      });
      final result = await service.decide(
        refundId: 'r1',
        approve: false,
        reason: 'Policy violation',
      );
      expect(result['status'], 'rejected');
    });

    test('markPaid posts to paid endpoint', () async {
      api.returnsPost('/organizations/org-001/refunds/r1/paid/', {
        'id': 'r1',
        'status': 'paid',
      });
      final result = await service.markPaid(
        refundId: 'r1',
        payoutReference: 'TRF-001',
      );
      expect(result['status'], 'paid');
    });

    test('complete posts to complete endpoint', () async {
      api.returnsPost('/organizations/org-001/refunds/r1/complete/', {
        'id': 'r1',
        'status': 'completed',
      });
      final result = await service.complete('r1');
      expect(result['status'], 'completed');
    });

    test('throws ApiException when API returns error', () async {
      expect(service.get('unknown'), throwsA(isA<ApiException>()));
    });
  });
}
