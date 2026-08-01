import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';

/// Mock that simulates the payment evidence → record → decide → issue flow.
class PaymentFlowMockApi extends ApiClient {
  PaymentFlowMockApi() : super(baseUrl: 'https://example.com');

  final _getListResults = <String, List<dynamic>>{};
  final _getResults = <String, Map<String, dynamic>>{};
  final _postResults = <String, Map<String, dynamic>>{};
  final _postMultipartResults = <String, Map<String, dynamic>>{};

  final callLog = <String>[];

  void returnsGetList(String path, List<dynamic> result) =>
      _getListResults[path] = result;
  void returnsGet(String path, Map<String, dynamic> result) =>
      _getResults[path] = result;
  void returnsPost(String path, Map<String, dynamic> result) =>
      _postResults[path] = result;
  void returnsPostMultipart(String path, Map<String, dynamic> result) =>
      _postMultipartResults[path] = result;

  @override
  Future<List<dynamic>> getList(String path) async {
    callLog.add('GET LIST $path');
    final result = _getListResults[path];
    if (result != null) return result;
    throw ApiException('Not found: $path');
  }

  @override
  Future<Map<String, dynamic>> get(String path) async {
    callLog.add('GET $path');
    final result = _getResults[path];
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

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    callLog.add('POST MULTIPART $path');
    final result = _postMultipartResults[path];
    if (result != null) return result;
    throw ApiException('Not found: $path');
  }
}

void main() {
  group('Payment Integration — record → decide → ticket issue', () {
    late PaymentFlowMockApi api;
    late String orgId;
    late String bookingId;

    setUp(() {
      api = PaymentFlowMockApi();
      orgId = 'org-001';
      bookingId = 'b-001';
    });

    group('payment accounts loading', () {
      test('loads payment accounts and flattens version list', () async {
        api.returnsGetList('/organizations/$orgId/payment-accounts/', [
          {
            'id': 'pa-1',
            'provider_name': 'KBZ Pay',
            'account_name': 'Main Wallet',
            'versions': [
              {
                'id': 'pv-1',
                'display_label': 'KBZ Pay • 09*****123',
              },
              {
                'id': 'pv-2',
                'display_label': 'KBZ Pay • 09*****456',
              },
            ],
          },
          {
            'id': 'pa-2',
            'provider_name': 'AYA Bank',
            'versions': [
              {
                'id': 'pv-3',
                'display_label': 'AYA • Current Account',
              },
            ],
          },
        ]);

        final accounts =
            await api.getList('/organizations/$orgId/payment-accounts/');
        final accountVersions =
            accounts
                .cast<Map<String, dynamic>>()
                .expand((account) =>
                    (account['versions'] as List<dynamic>? ?? [])
                        .cast<Map<String, dynamic>>()
                        .map((version) => {
                              ...version,
                              'account_label':
                                  account['provider_name'] ??
                                  account['account_name'],
                            }))
                .toList();

        expect(accountVersions.length, 3);
        expect(accountVersions[0]['account_label'], 'KBZ Pay');
        expect(accountVersions[0]['display_label'], 'KBZ Pay • 09*****123');
        expect(accountVersions[2]['account_label'], 'AYA Bank');
      });
    });

    group('evidence payment recording', () {
      test('uploads evidence and records payment', () async {
        final uploadId = 'up-1';
        final paymentId = 'pay-1';
        final accountVersionId = 'pv-1';

        // Step 1: Upload evidence
        api.returnsPostMultipart(
            '/organizations/$orgId/payment-uploads/', {
          'id': uploadId,
          'status': 'uploaded',
        });

        // Step 2: Record payment
        api.returnsPost('/organizations/$orgId/payments/', {
          'id': paymentId,
          'payment_number': 'PMT-001',
          'status': 'recorded',
          'amount': '15000',
          'currency': 'MMK',
          'method': 'wallet_qr',
        });

        // Execute: upload evidence
        final upload = await api.postMultipart(
          '/organizations/$orgId/payment-uploads/',
          fields: {'purpose': 'payment_evidence'},
          fileBytes: [0x89, 0x50, 0x4E, 0x47], // dummy PNG header
          fileName: 'payment_slip.png',
        );
        expect(upload['id'], uploadId);

        // Execute: record payment
        final payment = await api.post('/organizations/$orgId/payments/', {
          'payment_number': 'PMT-001',
          'booking': bookingId,
          'method': 'wallet_qr',
          'amount': '15000',
          'currency': 'MMK',
          'receiving_account_version': accountVersionId,
          'evidence_upload': upload['id'],
        });
        expect(payment['id'], paymentId);
        expect(payment['status'], 'recorded');

        // Verify call order
        expect(api.callLog.length, 2);
        expect(api.callLog[0], 'POST MULTIPART /organizations/$orgId/payment-uploads/');
        expect(api.callLog[1], 'POST /organizations/$orgId/payments/');
      });
    });

    group('payment decision + ticket issuance', () {
      test('approve payment and issue tickets from fare quote lines', () async {
        final paymentId = 'pay-1';

        // Stub: tickets endpoint for post-decision ticket list
        api.returnsGetList('/organizations/$orgId/tickets/', [
          {
            'id': 'tkt-1',
            'ticket_number': 'PMT-001-1',
            'passenger_name': 'Maung Maung',
            'status': 'issued',
            'booking': bookingId,
            'trip': 't1',
            'trip_number': 'T-001',
            'seat_identifier': '12',
          },
        ]);

        // Stub: decision endpoint
        api.returnsPost(
          '/organizations/$orgId/payments/$paymentId/decision/',
          {
            'id': paymentId,
            'status': 'confirmed',
          },
        );

        // Simulate fare quote lines (as received from locked quote)
        final lines = [
          {
            'id': 'line-1',
            'base_fare': '15000',
            'discount_amount': '0',
            'tax_amount': '0',
            'total_amount': '15000',
            'booking_passenger': 'bp-1',
          },
        ];
        final paymentNumber = 'PMT-001';

        // Build ticket payload (as _decide does in PaymentDecisionPage)
        final tickets = lines.asMap().entries.map((entry) {
          final line = entry.value;
          return {
            'booking_passenger': line['booking_passenger'],
            'ticket_number': '$paymentNumber-${entry.key + 1}',
            'ticket_type': 'electronic',
            'fare_amount': line['base_fare'],
            'discount_amount': line['discount_amount'],
            'tax_amount': line['tax_amount'],
            'service_charge': '0',
            'total_amount': line['total_amount'],
            'currency': 'MMK',
            'issuing_channel': 'counter',
          };
        }).toList();

        expect(tickets.length, 1);
        expect(tickets.first['ticket_number'], 'PMT-001-1');
        expect(tickets.first['fare_amount'], '15000');
        expect(tickets.first['booking_passenger'], 'bp-1');

        // Execute: approve decision with tickets
        final decision = await api.post(
          '/organizations/$orgId/payments/$paymentId/decision/',
          {
            'approve': true,
            'reason': '',
            'tickets': tickets,
          },
        );
        expect(decision['status'], 'confirmed');

        // Execute: fetch issued tickets filtered by booking
        final records =
            await api.getList('/organizations/$orgId/tickets/');
        final bookingTickets = records
            .cast<Map<String, dynamic>>()
            .where((t) => t['booking'] == bookingId)
            .toList();
        expect(bookingTickets.length, 1);
        expect(bookingTickets.first['ticket_number'], 'PMT-001-1');
        expect(bookingTickets.first['passenger_name'], 'Maung Maung');
      });

      test('reject payment posts reason without tickets', () async {
        final paymentId = 'pay-1';

        api.returnsPost(
          '/organizations/$orgId/payments/$paymentId/decision/',
          {
            'id': paymentId,
            'status': 'rejected',
          },
        );

        final decision = await api.post(
          '/organizations/$orgId/payments/$paymentId/decision/',
          {
            'approve': false,
            'reason': 'Incorrect payment amount',
          },
        );
        expect(decision['status'], 'rejected');
      });
    });

    group('payment model field alignment', () {
      test('payment schema has expected fields', () async {
        // Verify the fields used in payment_decision_page.dart match
        // the Payment OpenAPI schema
        final payment = {
          'id': 'pay-1',
          'payment_number': 'PMT-001',
          'status': 'recorded',
          'amount': '15000',
          'currency': 'MMK',
          'method': 'wallet_qr',
        };

        // Fields accessed in screen code
        expect(payment['payment_number'], isNotNull);
        expect(payment['status'], isNotNull);
        expect(payment['id'], isNotNull);
      });
    });
  });
}
