import '../../core/network/api_client.dart';
import '../models/booking_models.dart';
import '../models/trip_models.dart';
import 'result.dart';

/// Repository for passenger booking flows: travelers, seat locks, bookings.
///
/// Lock calls map `ApiException` (e.g. seat-conflict 409) to [Err] so screens
/// can refresh the seat grid on conflict — same behaviour as today, but with
/// typed results.
class BookingRepository {
  BookingRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  /// Saved travelers for the current passenger (optional — may be empty).
  Future<Result<List<Map<String, dynamic>>>> travelers() async {
    try {
      final data = await _api.get('/passenger/travelers/');
      return Ok(extractMapList(data));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to load travelers: $e');
    }
  }

  /// Create a traveler. Returns the created traveler map.
  Future<Result<Map<String, dynamic>>> createTraveler(
    Map<String, dynamic> payload,
  ) async {
    try {
      final data = await _api.post('/passenger/travelers/', payload);
      return Ok(data);
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to save traveler: $e');
    }
  }

  /// Acquire a server-side seat hold.
  Future<Result<Map<String, dynamic>>> acquireLock(
    Map<String, dynamic> payload,
  ) async {
    try {
      final lock = await _api.post('/passenger/seat-locks/', payload);
      return Ok(lock);
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Failed to hold seat: $e');
    }
  }

  /// Release a seat hold (best-effort — server TTL is the backstop).
  Future<void> releaseLock(String lockId) async {
    try {
      await _api.delete('/passenger/seat-locks/$lockId/');
    } catch (_) {
      // Best-effort by design.
    }
  }

  /// Create a booking for held seats.
  Future<Result<BookingConfirmation>> createBooking(
    Map<String, dynamic> payload,
  ) async {
    try {
      final booking = await _api.post('/passenger/bookings/', payload);
      return Ok(BookingConfirmation.fromJson(booking));
    } on ApiException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err('Booking failed: $e');
    }
  }
}
