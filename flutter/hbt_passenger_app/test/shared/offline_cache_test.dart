import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hbt_passenger_app/core/network/api_client.dart';
import 'package:hbt_passenger_app/infrastructure/database/app_cache_database.dart';
import 'package:hbt_passenger_app/shared/models/booking_models.dart';
import 'package:hbt_passenger_app/shared/models/trip_models.dart';
import 'package:hbt_passenger_app/shared/repositories/result.dart';
import 'package:hbt_passenger_app/shared/repositories/ticket_repository.dart';
import 'package:hbt_passenger_app/shared/repositories/trip_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppCacheDatabase.instance.clear();
  });

  tearDown(() async {
    await AppCacheDatabase.instance.close();
  });

  ApiClient client(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(baseUrl: 'https://example.test', client: MockClient(handler));

  http.Response json(Object body, {int status = 200}) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  group('AppCacheDatabase', () {
    test('put/get roundtrip', () async {
      await AppCacheDatabase.instance.put('k1', {'a': 1});
      final raw = await AppCacheDatabase.instance.get('k1');
      expect(raw, {'a': 1});
    });

    test('fetchedAt records timestamp', () async {
      await AppCacheDatabase.instance.put('k1', {'a': 1});
      final at = await AppCacheDatabase.instance.fetchedAt('k1');
      expect(at, isNotNull);
      expect(
        DateTime.now().difference(at!).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('missing keys return null', () async {
      expect(await AppCacheDatabase.instance.get('nope'), isNull);
      expect(await AppCacheDatabase.instance.fetchedAt('nope'), isNull);
    });

    test('put replaces existing entry', () async {
      await AppCacheDatabase.instance.put('k1', {'a': 1});
      await AppCacheDatabase.instance.put('k1', {'a': 2});
      expect(await AppCacheDatabase.instance.get('k1'), {'a': 2});
    });

    test('clear removes everything', () async {
      await AppCacheDatabase.instance.put('k1', {'a': 1});
      await AppCacheDatabase.instance.clear();
      expect(await AppCacheDatabase.instance.get('k1'), isNull);
    });
  });

  group('TripRepository offline fallback', () {
    test('serves cache with stale flag when network fails', () async {
      final cache = AppCacheDatabase.instance;
      // First request succeeds and caches.
      var online = true;
      final api = client((req) async {
        if (!online) return json({'detail': 'offline'}, status: 503);
        return json({
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
      final repo = TripRepository(api: api, cache: cache);

      final first = await repo.searchTrips(
        pickupStopId: 's1',
        dropoffStopId: 's2',
        date: '2026-08-02',
      );
      expect(first.isOk, isTrue);
      expect((first as Ok).stale, isFalse);

      // Network dies: repository must fall back to cache, flagged stale.
      online = false;
      final second = await repo.searchTrips(
        pickupStopId: 's1',
        dropoffStopId: 's2',
        date: '2026-08-02',
      );
      expect(second.isOk, isTrue);
      final ok = second as Ok<List<TripSummary>>;
      expect(ok.stale, isTrue);
      expect(ok.value.first.tripNumber, 'HBT-101');
    });

    test('returns network error when no cache exists', () async {
      final api = client((req) async => json({'detail': 'offline'}, status: 503));
      final repo = TripRepository(api: api, cache: AppCacheDatabase.instance);
      final result = await repo.searchTrips(
        pickupStopId: 's1',
        dropoffStopId: 's2',
        date: '2026-08-02',
      );
      expect(result.isErr, isTrue);
    });
  });

  group('TicketRepository offline fallback', () {
    test('serves cached tickets stale when offline', () async {
      final cache = AppCacheDatabase.instance;
      var online = true;
      final api = client((req) async {
        if (!online) return json({'detail': 'offline'}, status: 503);
        return json({
          'results': [
            {'id': 't1', 'status': 'issued'},
          ],
        });
      });
      final repo = TicketRepository(api: api, cache: cache);

      final first = await repo.myTickets();
      expect((first as Ok).stale, isFalse);

      online = false;
      final second = await repo.myTickets();
      final ok = second as Ok<List<TicketSummary>>;
      expect(ok.stale, isTrue);
      expect(ok.value.first.status, 'issued');
    });
  });
}
