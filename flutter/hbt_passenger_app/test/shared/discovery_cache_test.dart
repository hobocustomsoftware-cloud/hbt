import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hbt_passenger_app/core/network/api_client.dart';
import 'package:hbt_passenger_app/infrastructure/database/app_cache_database.dart';
import 'package:hbt_passenger_app/shared/repositories/result.dart';
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

  group('discovery caching (F-26)', () {
    test('terminals: fresh cache serves without network call', () async {
      var calls = 0;
      final api = client((req) async {
        calls++;
        return json({
          'results': [
            {'id': 't1', 'name': 'Aung Mingalar', 'city': 'Yangon'},
          ],
        });
      });
      final repo = TripRepository(api: api, cache: AppCacheDatabase.instance);

      final first = await repo.terminals();
      expect(first.isOk, isTrue);
      expect(calls, 1);

      final second = await repo.terminals();
      expect(second.isOk, isTrue);
      expect((second as Ok).stale, isFalse);
      expect(calls, 1, reason: 'fresh cache must skip the network');
    });

    test('terminals: stale cache served on network failure after TTL',
        () async {
      var online = true;
      final api = client((req) async {
        if (!online) return json({'detail': 'offline'}, status: 503);
        return json({
          'results': [
            {'id': 't1', 'name': 'Aung Mingalar', 'city': 'Yangon'},
          ],
        });
      });
      final repo = TripRepository(
        api: api,
        cache: AppCacheDatabase.instance,
        discoveryTtl: const Duration(milliseconds: 50),
      );

      await repo.terminals();
      online = false;
      // Age the entry past the tiny TTL so the fresh path is skipped.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final result = await repo.terminals();
      expect(result.isOk, isTrue);
      expect((result as Ok).stale, isTrue);
    });

    test('orgRoutes: repeated calls hit cache, not network', () async {
      var calls = 0;
      final api = client((req) async {
        calls++;
        return json({
          'results': [
            {'id': 'r1', 'name': 'Yangon-Mandalay'},
          ],
        });
      });
      final repo = TripRepository(api: api, cache: AppCacheDatabase.instance);

      await repo.orgRoutes('org-1');
      expect(calls, 1);
      final again = await repo.orgRoutes('org-1');
      expect(again.length, 1);
      expect(calls, 1);
    });

    test('orgRoutes: stale cache beats empty list on failure', () async {
      var online = true;
      final api = client((req) async {
        if (!online) return json({'detail': 'offline'}, status: 503);
        return json({
          'results': [
            {'id': 'r1', 'name': 'Yangon-Mandalay'},
          ],
        });
      });
      final repo = TripRepository(api: api, cache: AppCacheDatabase.instance);

      await repo.orgRoutes('org-1');
      online = false;
      final result = await repo.orgRoutes('org-1');
      expect(result.length, 1, reason: 'stale cache preferred over empty');
    });

    test('routeStops: cached per route', () async {
      var calls = 0;
      final api = client((req) async {
        calls++;
        return json({
          'results': [
            {'id': 's1', 'name': 'Stop 1'},
          ],
        });
      });
      final repo = TripRepository(api: api, cache: AppCacheDatabase.instance);

      await repo.routeStops('org-1', 'route-1');
      await repo.routeStops('org-1', 'route-1');
      expect(calls, 1);

      // Different route -> different cache key -> another call.
      await repo.routeStops('org-1', 'route-2');
      expect(calls, 2);
    });
  });
}
