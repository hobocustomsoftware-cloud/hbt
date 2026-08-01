import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_passenger_app/shared/models/booking_models.dart';
import 'package:hbt_passenger_app/shared/models/trip_models.dart';
import 'package:hbt_passenger_app/shared/repositories/result.dart';

void main() {
  group('Result<T>', () {
    test('Ok carries value and reports isOk', () {
      const result = Ok<String>('hello');
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 'hello');
      expect(result.errorMessage, isNull);
    });

    test('Err carries message and reports isErr', () {
      const result = Err<String>('boom');
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.errorMessage, 'boom');
    });

    test('Err can carry a technical cause', () {
      final cause = StateError('inner');
      final result = Err<int>('failed', cause: cause);
      expect(result.cause, same(cause));
    });
  });

  group('TripSummary', () {
    test('parses full payload', () {
      final trip = TripSummary.fromJson({
        'id': 'trip-1',
        'trip_number': 'HBT-101',
        'organization_name': 'Shwe Yoke Lay',
        'planned_departure_at': '2026-08-02T09:30:00Z',
      });
      expect(trip.id, 'trip-1');
      expect(trip.tripNumber, 'HBT-101');
      expect(trip.organizationName, 'Shwe Yoke Lay');
      expect(trip.departureLabel, '2026-08-02 09:30');
    });

    test('tolerates missing fields', () {
      final trip = TripSummary.fromJson({'id': 'x'});
      expect(trip.tripNumber, 'Trip');
      expect(trip.organizationName, 'Bus Co.');
      expect(trip.plannedDepartureAt, isNull);
      expect(trip.departureLabel, '-');
    });

    test('departure label shortens long timestamps', () {
      final trip = TripSummary.fromJson({
        'planned_departure_at': '2026-08-02T09:30:00.123456+06:30',
      });
      expect(trip.departureLabel.length, 16);
    });
  });

  group('SeatInfo', () {
    test('available when status available and no active lock', () {
      final seat = SeatInfo.fromJson({
        'id': 's1',
        'label': 'A1',
        'status': 'available',
      });
      expect(seat.isAvailable, isTrue);
    });

    test('unavailable when held by another', () {
      final seat = SeatInfo.fromJson({
        'id': 's1',
        'label': 'A1',
        'status': 'available',
        'active_lock': {'id': 'lock-1'},
      });
      expect(seat.isAvailable, isFalse);
    });

    test('unavailable when booked', () {
      final seat = SeatInfo.fromJson({
        'id': 's1',
        'label': 'A1',
        'status': 'booked',
      });
      expect(seat.isAvailable, isFalse);
    });
  });

  group('BookingConfirmation', () {
    test('shortId truncates long ids safely', () {
      const b = BookingConfirmation(
        id: '1234567890abcdef',
        seat: 'A1',
        raw: {},
      );
      expect(b.shortId, '12345678');
    });

    test('shortId returns short ids unchanged (no crash)', () {
      const b = BookingConfirmation(id: 'abc', seat: null, raw: {});
      expect(b.shortId, 'abc');
    });
  });

  group('TicketSummary', () {
    test('parses status', () {
      final t = TicketSummary.fromJson({
        'id': 't-1',
        'status': 'issued',
      });
      expect(t.id, 't-1');
      expect(t.status, 'issued');
    });
  });

  group('extractMapList', () {
    test('handles bare arrays', () {
      final list = extractMapList([
        {'id': 'a'},
        {'id': 'b'},
      ]);
      expect(list.length, 2);
    });

    test('handles paginated results', () {
      final list = extractMapList({
        'results': [
          {'id': 'a'},
        ],
      });
      expect(list.length, 1);
    });

    test('returns empty for junk', () {
      expect(extractMapList('nope'), isEmpty);
      expect(extractMapList({'no': 'results'}), isEmpty);
    });
  });
}
