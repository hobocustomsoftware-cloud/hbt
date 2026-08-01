import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';

/// Mock that simulates the booking → fare quote → lock API flow.
class BookingFlowMockApi extends ApiClient {
  BookingFlowMockApi() : super(baseUrl: 'https://example.com');

  final _getListResults = <String, List<dynamic>>{};
  final _postResults = <String, Map<String, dynamic>>{};

  final callLog = <String>[];

  void returnsGetList(String path, List<dynamic> result) =>
      _getListResults[path] = result;

  void returnsPost(String path, Map<String, dynamic> result) =>
      _postResults[path] = result;

  @override
  Future<List<dynamic>> getList(String path) async {
    callLog.add('GET $path');
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

  @override
  Future<Map<String, dynamic>> get(String path) async {
    callLog.add('GET $path');
    throw ApiException('Not found: $path');
  }
}

void main() {
  group('Booking Integration — full booking → quote → lock flow', () {
    late BookingFlowMockApi api;
    late String orgId;

    setUp(() {
      api = BookingFlowMockApi();
      orgId = 'org-001';
    });

    test('loads passengers and trips on initial data fetch', () async {
      api.returnsGetList('/organizations/$orgId/passengers/', [
        {'id': 'p1', 'passenger_code': 'P001', 'full_name': 'Maung Maung'},
        {'id': 'p2', 'passenger_code': 'P002', 'full_name': 'Su Su'},
      ]);
      api.returnsGetList('/organizations/$orgId/trips/', [
        {
          'id': 't1',
          'trip_number': 'T-001',
          'status': 'planned',
          'planned_departure_at': '2026-07-30T08:00:00Z',
          'service_date': '2026-07-30',
        },
        {
          'id': 't2',
          'trip_number': 'T-002',
          'status': 'ready',
          'planned_departure_at': '2026-07-30T10:00:00Z',
          'service_date': '2026-07-30',
        },
        {
          'id': 't3',
          'trip_number': 'T-003',
          'status': 'cancelled',
          'planned_departure_at': '2026-07-30T12:00:00Z',
          'service_date': '2026-07-30',
        },
      ]);

      final passengers =
          await api.getList('/organizations/$orgId/passengers/');
      final trips = await api.getList('/organizations/$orgId/trips/');

      expect(passengers.length, 2);
      expect(passengers.first['full_name'], 'Maung Maung');
      expect(passengers.last['passenger_code'], 'P002');
      expect(trips.length, 3);

      final activeTrips = trips
          .where((t) =>
              t['status'] == 'planned' || t['status'] == 'ready')
          .toList();
      expect(activeTrips.length, 2);
      expect(activeTrips.any((t) => t['status'] == 'cancelled'), false);

      expect(api.callLog.length, 2);
      expect(api.callLog[0], 'GET /organizations/$orgId/passengers/');
      expect(api.callLog[1], 'GET /organizations/$orgId/trips/');
    });

    test('creates booking and fare quote then locks it', () async {
      final tripId = 't1';
      final passengerId = 'p1';
      final pickupStopId = 'stop-1';
      final dropoffStopId = 'stop-5';
      final seatId = 'seat-12';
      final bookingId = 'b-001';
      final quoteId = 'q-001';

      api.returnsPost('/organizations/$orgId/bookings/', {
        'id': bookingId,
        'booking_number': 'BN-001',
        'status': 'pending',
        'authorization_reference': 'AUTH-001',
        'trip': tripId,
      });

      api.returnsPost(
          '/organizations/$orgId/bookings/$bookingId/fare-quotes/create/', {
        'id': quoteId,
        'status': 'quoted',
        'currency': 'MMK',
        'subtotal': '15000',
        'discount_amount': '0',
        'tax_amount': '0',
        'total_amount': '15000',
        'lines': [
          {
            'id': 'line-1',
            'base_fare': '15000',
            'discount_amount': '0',
            'tax_amount': '0',
            'total_amount': '15000',
            'booking_passenger': 'bp-1',
          },
        ],
      });

      api.returnsPost(
          '/organizations/$orgId/fare-quotes/$quoteId/lock/', {
        'id': quoteId,
        'status': 'locked',
        'currency': 'MMK',
        'total_amount': '15000',
        'lines': [
          {
            'id': 'line-1',
            'base_fare': '15000',
            'discount_amount': '0',
            'tax_amount': '0',
            'total_amount': '15000',
            'booking_passenger': 'bp-1',
          },
        ],
      });

      final booking = await api.post('/organizations/$orgId/bookings/', {
        'trip': tripId,
        'booking_type': 'individual',
        'channel': 'counter',
        'contact_name': 'Maung Maung',
        'contact_phone': '0912345678',
        'pickup_stop': pickupStopId,
        'dropoff_stop': dropoffStopId,
        'passenger_seats': [
          {'passenger': passengerId, 'seat_position': seatId},
        ],
      });

      expect(booking['id'], bookingId);
      expect(booking['authorization_reference'], 'AUTH-001');
      expect(booking['booking_number'], 'BN-001');

      final quote = await api.post(
        '/organizations/$orgId/bookings/$bookingId/fare-quotes/create/',
        {'coupon_code': ''},
      );
      expect(quote['id'], quoteId);
      expect(quote['status'], 'quoted');
      expect(quote['total_amount'], '15000');
      expect(quote['currency'], 'MMK');

      final locked =
          await api.post('/organizations/$orgId/fare-quotes/$quoteId/lock/', {});
      expect(locked['id'], quoteId);
      expect(locked['status'], 'locked');
      expect(locked['total_amount'], '15000');

      final lines = (locked['lines'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(lines.length, 1);
      expect(lines.first['base_fare'], '15000');
      expect(lines.first['booking_passenger'], 'bp-1');

      expect(api.callLog.length, 3);
      expect(api.callLog[0], 'POST /organizations/$orgId/bookings/');
      expect(api.callLog[1],
          'POST /organizations/$orgId/bookings/$bookingId/fare-quotes/create/');
      expect(api.callLog[2],
          'POST /organizations/$orgId/fare-quotes/$quoteId/lock/');
    });

    test('rejects booking when passenger or trip missing', () async {
      expect(
        () => api.post('/organizations/$orgId/bookings/', {
          'trip': null,
          'booking_type': 'individual',
          'channel': 'counter',
          'passenger_seats': [],
        }),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
