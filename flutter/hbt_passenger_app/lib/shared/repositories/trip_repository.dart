import '../../core/network/api_client.dart';
import '../../infrastructure/database/app_cache_database.dart';
import '../models/trip_models.dart';
import 'result.dart';

/// Repository for passenger trip search, routes, stops and seat maps.
///
/// Wraps [ApiClient] and returns [Result] values so screens never touch raw
/// HTTP errors. When an [AppCacheDatabase] is provided, successful reads are
/// cached and network failures fall back to the cache (marked `stale`),
/// giving offline read capability for schedule data.
class TripRepository {
  TripRepository({
    required ApiClient api,
    AppCacheDatabase? cache,
    Duration discoveryTtl = const Duration(hours: 24),
  })  : _api = api,
        _cache = cache,
        _discoveryTtl = discoveryTtl;

  final ApiClient _api;
  final AppCacheDatabase? _cache;

  /// Reference data (terminals, orgs, routes, stops) changes rarely; cache
  /// it for a day so repeat searches skip the ~30-call discovery fan-out
  /// (F-26 N+1 fix). Stale fallback still applies on network failure.
  /// Injectable for tests.
  final Duration _discoveryTtl;

  /// All terminals (pickup/dropoff cities). Cached for [_discoveryTtl].
  Future<Result<List<Map<String, dynamic>>>> terminals() async {
    const path = '/terminals/';
    final cached = await _freshDiscovery(path);
    if (cached != null) return Ok(extractMapList(cached));
    try {
      final data = await _api.get(path);
      await _cache?.put(path, data);
      return Ok(extractMapList(data));
    } on ApiException catch (e) {
      return _staleDiscoveryOrErr(path, e.message);
    } catch (e) {
      return Err('Failed to load terminals: $e');
    }
  }

  /// Organizations the passenger belongs to (drives route discovery).
  /// Cached for [_discoveryTtl].
  Future<Result<List<Map<String, dynamic>>>> organizations() async {
    const path = '/me/organizations/';
    final cached = await _freshDiscovery(path);
    if (cached != null) return Ok(extractMapList(cached));
    try {
      final data = await _api.get(path);
      await _cache?.put(path, data);
      return Ok(extractMapList(data));
    } on ApiException catch (e) {
      return _staleDiscoveryOrErr(path, e.message);
    } catch (e) {
      return Err('Failed to load organizations: $e');
    }
  }

  /// Routes for one organization. Failures return an empty list so a single
  /// broken org cannot break the whole search (matches screen behaviour); a
  /// stale cache is preferred over an empty list. Cached for [_discoveryTtl].
  Future<List<Map<String, dynamic>>> orgRoutes(String orgId) async {
    final path = '/organizations/$orgId/routes/';
    final cached = await _freshDiscovery(path);
    if (cached != null) return extractMapList(cached);
    try {
      final data = await _api.get(path);
      await _cache?.put(path, data);
      return extractMapList(data);
    } on ApiException {
      return _staleDiscoveryList(path);
    } catch (_) {
      return _staleDiscoveryList(path);
    }
  }

  /// Stops for a route. Failures return an empty list (see [orgRoutes]); a
  /// stale cache is preferred over an empty list. Cached for [_discoveryTtl].
  Future<List<Map<String, dynamic>>> routeStops(
    String orgId,
    String routeId,
  ) async {
    final path = '/organizations/$orgId/routes/$routeId/stops/';
    final cached = await _freshDiscovery(path);
    if (cached != null) return extractMapList(cached);
    try {
      final data =
          await _api.get(path);
      await _cache?.put(path, data);
      return extractMapList(data);
    } on ApiException {
      return _staleDiscoveryList(path);
    } catch (_) {
      return _staleDiscoveryList(path);
    }
  }

  /// Search trips between two stops on a date (YYYY-MM-DD).
  ///
  /// Caches the successful response keyed by the search query; on network
  /// failure serves the cached response with `stale: true`.
  Future<Result<List<TripSummary>>> searchTrips({
    required String pickupStopId,
    required String dropoffStopId,
    required String date,
  }) async {
    final path = '/passenger/trips/search/'
        '?pickup_stop=$pickupStopId'
        '&dropoff_stop=$dropoffStopId'
        '&date=$date';
    try {
      final data = await _api.get(path);
      final trips = extractMapList(data)
          .map(TripSummary.fromJson)
          .toList(growable: false);
      await _cache?.put(path, data);
      return Ok(trips);
    } on ApiException catch (e) {
      return _cachedOrErr<List<TripSummary>>(path, e.message, (raw) =>
          extractMapList(raw).map(TripSummary.fromJson).toList(growable: false));
    } catch (e) {
      return Err('Search failed: $e');
    }
  }

  /// Full detail for one trip (cached for offline reads).
  Future<Result<TripDetail>> tripDetail(String tripId) async {
    final path = '/passenger/trips/$tripId/';
    try {
      final data = await _api.get(path);
      await _cache?.put(path, data);
      return Ok(TripDetail.fromJson(data));
    } on ApiException catch (e) {
      return _cachedOrErr<TripDetail>(path, e.message, (raw) {
        final map = raw is Map<String, dynamic>
            ? raw
            : const <String, dynamic>{};
        return TripDetail.fromJson(map);
      });
    } catch (e) {
      return Err('Failed to load trip: $e');
    }
  }

  /// Seat map for a trip between two stops (cached for offline reads).
  /// Returns the raw seat list plus the full payload (screen reads more
  /// fields than the DTO exposes).
  Future<Result<List<SeatInfo>>> seats({
    required String tripId,
    required String? pickupStopId,
    required String? dropoffStopId,
  }) async {
    final query = StringBuffer('/passenger/trips/$tripId/seats/');
    if (pickupStopId != null && dropoffStopId != null) {
      query
        ..write('?pickup_stop=$pickupStopId')
        ..write('&dropoff_stop=$dropoffStopId');
    }
    final path = query.toString();
    List<SeatInfo> parse(Object? rawPayload) {
      final data = rawPayload is Map<String, dynamic>
          ? rawPayload
          : const <String, dynamic>{};
      final rawSeats = data['seats'];
      final seats = rawSeats is List
          ? rawSeats.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      return seats.map(SeatInfo.fromJson).toList(growable: false);
    }

    try {
      final data = await _api.get(path);
      await _cache?.put(path, data);
      return Ok(parse(data));
    } on ApiException catch (e) {
      return _cachedOrErr<List<SeatInfo>>(path, e.message, parse);
    } catch (e) {
      return Err('Failed to load seats: $e');
    }
  }

  /// Serve a cached payload when one exists; otherwise return the original
  /// network error. Cached results are flagged `stale: true`.
  Future<Result<T>> _cachedOrErr<T>(
    String cacheKey,
    String message,
    T Function(Object? raw) parse,
  ) async {
    final cache = _cache;
    if (cache == null) return Err(message);
    try {
      final raw = await cache.get(cacheKey);
      if (raw == null) return Err(message);
      return Ok(parse(raw), stale: true);
    } catch (_) {
      return Err(message);
    }
  }

  /// Fresh discovery payload (age < [_discoveryTtl]) or null.
  Future<Object?> _freshDiscovery(String cacheKey) async {
    final cache = _cache;
    if (cache == null) return null;
    try {
      final at = await cache.fetchedAt(cacheKey);
      if (at == null) return null;
      final age = DateTime.now().difference(at);
      if (age > _discoveryTtl) return null;
      return cache.get(cacheKey);
    } catch (_) {
      return null;
    }
  }

  /// Discovery result fallback: stale cache or the original network error.
  Future<Result<List<Map<String, dynamic>>>> _staleDiscoveryOrErr(
    String cacheKey,
    String message,
  ) async {
    final cache = _cache;
    if (cache != null) {
      try {
        final raw = await cache.get(cacheKey);
        if (raw != null) return Ok(extractMapList(raw), stale: true);
      } catch (_) {
        // fall through to the network error below
      }
    }
    return Err(message);
  }

  /// Discovery list fallback: stale cache if present, else empty list
  /// (matches the pre-cache per-org resilience contract).
  Future<List<Map<String, dynamic>>> _staleDiscoveryList(
    String cacheKey,
  ) async {
    final cache = _cache;
    if (cache != null) {
      try {
        final raw = await cache.get(cacheKey);
        if (raw != null) return extractMapList(raw);
      } catch (_) {
        // fall through to empty list below
      }
    }
    return <Map<String, dynamic>>[];
  }
}
