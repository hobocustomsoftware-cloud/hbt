import '../../core/network/api_client.dart';
import '../models/trip_models.dart';
import 'result.dart';

/// Repository for passenger trip search, routes, stops and seat maps.
///
/// Wraps [ApiClient] and returns [Result] values so screens never touch raw
/// HTTP errors. In M4a this is a passthrough; M4b adds the offline cache.
class TripRepository {
  TripRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

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
  Future<Result<List<TripSummary>>> searchTrips({
    required String pickupStopId,
    required String dropoffStopId,
    required String date,
  }) async {
    try {
      final data = await _api.get(
        '/passenger/trips/search/'
        '?pickup_stop=$pickupStopId'
        '&dropoff_stop=$dropoffStopId'
        '&date=$date',
      );
      final trips = extractMapList(data)
          .map(TripSummary.fromJson)
          .toList(growable: false);
      return Ok(trips);
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Search failed: $e');
    }
  }

  /// Full detail for one trip.
  Future<Result<TripDetail>> tripDetail(String tripId) async {
    try {
      final data = await _api.get('/passenger/trips/$tripId/');
      return Ok(TripDetail.fromJson(data));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load trip: $e');
    }
  }

  /// Seat map for a trip between two stops. Returns the raw seat list plus
  /// the full payload (the screen reads additional fields).
  Future<Result<List<SeatInfo>>> seats({
    required String tripId,
    required String? pickupStopId,
    required String? dropoffStopId,
  }) async {
    try {
      final query = StringBuffer('/passenger/trips/$tripId/seats/');
      if (pickupStopId != null && dropoffStopId != null) {
        query
          ..write('?pickup_stop=$pickupStopId')
          ..write('&dropoff_stop=$dropoffStopId');
      }
      final data = await _api.get(query.toString());
      final rawSeats = data['seats'];
      final seats = rawSeats is List
          ? rawSeats.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      return Ok(seats.map(SeatInfo.fromJson).toList(growable: false));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load seats: $e');
    }
  }
}
