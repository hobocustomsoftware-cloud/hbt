import '../../core/network/api_client.dart';
import '../models/booking_models.dart';
import '../models/trip_models.dart';
import 'result.dart';

/// Repository for passenger tickets.
class TicketRepository {
  TicketRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  /// All tickets for the current passenger.
  Future<Result<List<TicketSummary>>> myTickets() async {
    try {
      final data = await _api.get('/passenger/tickets/');
      final list = extractMapList(data);
      return Ok(list.map(TicketSummary.fromJson).toList(growable: false));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load tickets: $e');
    }
  }
}
