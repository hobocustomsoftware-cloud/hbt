import '../../core/network/api_client.dart';
import '../../infrastructure/database/app_cache_database.dart';
import '../models/booking_models.dart';
import '../models/trip_models.dart';
import 'result.dart';

/// Repository for passenger tickets (cached for offline reads).
class TicketRepository {
  TicketRepository({required ApiClient api, AppCacheDatabase? cache})
      : _api = api,
        _cache = cache;

  final ApiClient _api;
  final AppCacheDatabase? _cache;

  /// All tickets for the current passenger.
  Future<Result<List<TicketSummary>>> myTickets() async {
    const path = '/passenger/tickets/';
    try {
      final data = await _api.get(path);
      await _cache?.put(path, data);
      final list = extractMapList(data);
      return Ok(list.map(TicketSummary.fromJson).toList(growable: false));
    } on ApiException catch (e) {
      final cache = _cache;
      if (cache != null) {
        try {
          final raw = await cache.get(path);
          if (raw != null) {
            final list = extractMapList(raw);
            return Ok(list.map(TicketSummary.fromJson).toList(growable: false),
                stale: true);
          }
        } catch (_) {
          // fall through to the network error below
        }
      }
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load tickets: $e');
    }
  }
}
