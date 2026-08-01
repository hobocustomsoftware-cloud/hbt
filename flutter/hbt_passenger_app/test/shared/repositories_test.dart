import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hbt_passenger_app/core/network/api_client.dart';
import 'package:hbt_passenger_app/shared/repositories/booking_repository.dart';
import 'package:hbt_passenger_app/shared/repositories/ticket_repository.dart';
import 'package:hbt_passenger_app/shared/repositories/trip_repository.dart';

ApiClient _client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(baseUrl: 'https://example.test', client: MockClient(handler));

http.Response _json(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('TripRepository', () {
    test('searchTrips parses results and returns TripSummary list', () async {
      final api = _client((req) async {
        expect(req.url.path, '/passenger/trips/search/');
        return _json({
          'results': [
            {
              'id': 't1',
              'trip_number': 'HBT-101',
              'organization_name': 'Shwe',
              'planned_departure_at': '2026-08-02T09:30:00Z',
            },
          ],
        });
      });
      final repo = TripRepository(api: api);
      final result = await repo.searchTrips(
        pickupStopId: 's1',
        dropoffStopId: 's2',
        date: '2026-08-02',
      );
      expect(result.isOk, isTrue);
      final trips = result.valueOrNull!;
      expect(trips.length, 1);
      expect(trips.first.tripNumber, 'HBT-101');
      expect(trips.first.departureLabel, '2026-08-02 09:30');
    });

    test('searchTrips maps API errors to Err', () async {
      final api = _client((req) async => _json({'detail': 'no trips'}, status: 404));
      final repo = TripRepository(api: api);
      final result = await repo.searchTrips(
        pickupStopId: 's1',
        dropoffStopId: 's2',
        date: '2026-08-02',
      );
      expect(result.isErr, isTrue);
      expect(result.errorMessage, 'no trips');
    });

    test('orgRoutes and routeStops return empty list on failure (per-org resilience)',
        () async {
      final api = _client((req) async => _json({'detail': 'nope'}, status: 500));
      final repo = TripRepository(api: api);
      expect(await repo.orgRoutes('org1'), isEmpty);
      expect(await repo.routeStops('org1', 'r1'), isEmpty);
    });

    test('seats parses seat list with active_lock awareness', () async {
      final api = _client((req) async {
        expect(req.url.path, '/passenger/trips/t1/seats/');
        return _json({
          'seats': [
            {'id': 'a1', 'label': 'A1', 'status': 'available'},
            {'id': 'a2', 'label': 'A2', 'status': 'available', 'active_lock': {'id': 'l1'}},
          ],
        });
      });
      final repo = TripRepository(api: api);
      final result = await repo.seats(tripId: 't1', pickupStopId: 'p', dropoffStopId: 'd');
      final seats = result.valueOrNull!;
      expect(seats.length, 2);
      expect(seats[0].isAvailable, isTrue);
      expect(seats[1].isAvailable, isFalse);
    });
  });

  group('BookingRepository', () {
    test('acquireLock returns lock map on success', () async {
      final api = _client((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/passenger/seat-locks/');
        return _json({'id': 'lock-1', 'expires_at': '2026-08-02T10:00:00Z'});
      });
      final repo = BookingRepository(api: api);
      final result =
          await repo.acquireLock({'trip_id': 't1', 'seat_position': 'A1'});
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!['id'], 'lock-1');
    });

    test('acquireLock maps seat-conflict to Err', () async {
      final api = _client((req) async =>
          _json({'detail': 'Seat is held by another passenger.'}, status: 409));
      final repo = BookingRepository(api: api);
      final result =
          await repo.acquireLock({'trip_id': 't1', 'seat_position': 'A1'});
      expect(result.isErr, isTrue);
      expect(result.errorMessage, contains('held'));
    });

    test('releaseLock swallows errors (best-effort by design)', () async {
      var called = false;
      final api = _client((req) async {
        called = true;
        expect(req.method, 'DELETE');
        return _json({'detail': 'gone'}, status: 404);
      });
      final repo = BookingRepository(api: api);
      await repo.releaseLock('lock-1'); // must not throw
      expect(called, isTrue);
    });

    test('createBooking parses confirmation with safe shortId', () async {
      final api = _client((req) async {
        expect(req.url.path, '/passenger/bookings/');
        return _json({'id': 'short', 'seat': 'A1'});
      });
      final repo = BookingRepository(api: api);
      final result = await repo.createBooking({'trip': 't1', 'passenger_seats': []});
      final booking = result.valueOrNull!;
      expect(booking.shortId, 'short'); // no crash on short ids
      expect(booking.seat, 'A1');
    });
  });

  group('TicketRepository', () {
    test('myTickets parses paginated results', () async {
      final api = _client((req) async {
        expect(req.url.path, '/passenger/tickets/');
        return _json({
          'results': [
            {'id': 't1', 'status': 'issued'},
            {'id': 't2', 'status': 'validated'},
          ],
        });
      });
      final repo = TicketRepository(api: api);
      final result = await repo.myTickets();
      final tickets = result.valueOrNull!;
      expect(tickets.length, 2);
      expect(tickets[1].status, 'validated');
    });

    test('myTickets maps errors to Err', () async {
      final api = _client((req) async => _json({'detail': 'auth'}, status: 401));
      final repo = TicketRepository(api: api);
      final result = await repo.myTickets();
      expect(result.isErr, isTrue);
      expect(result.errorMessage, 'auth');
    });
  });
}
