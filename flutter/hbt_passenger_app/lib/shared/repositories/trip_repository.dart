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
  TripRepository({required ApiClient api, AppCacheDatabase? cache})
      : _api = api,
        _cache = cache;

  final ApiClient _api;
  final AppCacheDatabase? _cache;

  /// All terminals (pickup/dropoff cities).
  Future<Result<List<Map<String, dynamic>>>> terminals() async {
    try {
      final data = await _api.get('/terminals/');
      return Ok(extractMapList(data));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load terminals: $e');
    }
  }

  /// Organizations the passenger belongs to (drives route discovery).
  Future<Result<List<Map<String, dynamic>>>> organizations() async {
    try {
      final data = await _api.get('/me/organizations/');
      return Ok(extractMapList(data));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load organizations: $e');
    }
  }

  /// Routes for one organization. Failures return an empty list so a single
  /// broken org cannot break the whole search (matches screen behaviour).
  Future<List<Map<String, dynamic>>> orgRoutes(String orgId) async {
    try {
      final data = await _api.get('/organizations/$orgId/routes/');
      return extractMapList(data);
    } on ApiException {
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  /// Stops for a route. Failures return an empty list (see [orgRoutes]).
  Future<List<Map<String, dynamic>>> routeStops(
    String orgId,
    String routeId,
  ) async {
    try {
      final data =
          await _api.get('/organizations/$orgId/routes/$routeId/stops/');
      return extractMapList(data);
    } on ApiException {
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
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
}
