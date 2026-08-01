import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/seat_lock_models.dart';

/// Manages seat lock lifecycle for the current booking session.
///
/// Acquires a lock when a seat is selected, releases it on
/// successful booking, cancellation, or error. Monitors TTL and
/// automatically releases expired locks.
///
/// ## API endpoints
/// - `POST /organizations/{orgId}/seat-lock/` — acquire a lock
/// - `DELETE /organizations/{orgId}/seat-lock/{lockId}/` — release a lock
/// - `GET /organizations/{orgId}/seat-locks/` — list all active locks for a trip
/// - `POST /organizations/{orgId}/seat-lock/{lockId}/extend/` — extend lock TTL
class SeatLockController extends ChangeNotifier {
  SeatLockController({
    required ApiClient api,
    required String organizationId,
    required String tripId,
    this.userId,
    this.deviceId,
  })  : _api = api,
        _orgId = organizationId,
        _tripId = tripId;

  final ApiClient _api;
  final String _orgId;
  final String _tripId;
  final Set<String> _pendingLocks = {};

  /// Lock owner identity (set during session).
  String? userId;
  String? deviceId;

  SeatLock? _currentLock;
  Timer? _ttlTimer;
  bool _acquiring = false;
  bool _releasing = false;
  String? _error;
  Duration _remaining = Duration.zero;
  int _acquireRetries = 0;
  static const _maxAcquireRetries = 2;

  // ── Getters ──
  SeatLock? get currentLock => _currentLock;
  bool get hasActiveLock => _currentLock != null && _currentLock!.isValid;
  bool get acquiring => _acquiring;
  bool get releasing => _releasing;
  String? get error => _error;
  Duration get remaining => _remaining;
  bool get isExpired => _currentLock != null && !_currentLock!.isValid;

  /// Whether a lock operation is pending for the given seat.
  bool isLockPending(String seatPosition) =>
      _pendingLocks.contains(seatPosition);

  // ── Lock lifecycle ────────────────────────────────────────────────

  /// Acquire a lock on the given seat.
  ///
  /// If a lock is already held, it is released first before acquiring
  /// the new one (atomic swap). The request is idempotent: if the same
  /// owner already holds the lock, returns the existing lock.
  ///
  /// Retries automatically on transient failure (up to 2 retries with
  /// 500ms delay).
  Future<bool> acquire(String seatPosition) async {
    if (_acquiring) return false;

    // Release current lock if any
    if (_currentLock != null) {
      await _doRelease();
    }

    _acquiring = true;
    _error = null;
    _acquireRetries = 0;
    notifyListeners();

    try {
      _currentLock = await _doAcquire(seatPosition);
      _startTtlTimer();
      _pendingLocks.add(seatPosition);
      _acquiring = false;
      notifyListeners();
      return true;
    } on SeatLockConflictException catch (e) {
      _error = e.message;
      _acquiring = false;
      _currentLock = null;
      notifyListeners();
      return false;
    } on SeatLockExpiredException {
      _error = 'Lock expired. Please re-select the seat.';
      _acquiring = false;
      _currentLock = null;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _acquiring = false;
      _currentLock = null;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to lock seat: $e';
      _acquiring = false;
      notifyListeners();
      return false;
    }
  }

  /// Internal acquire with retry.
  Future<SeatLock> _doAcquire(String seatPosition) async {
    while (_acquireRetries < _maxAcquireRetries) {
      try {
        final response = await _api.post(
          '/organizations/$_orgId/seat-lock/',
          {
            'trip_id': _tripId,
            'seat_position': seatPosition,
            if (userId != null) 'held_by_user_id': userId,
            if (deviceId != null) 'held_by_device_id': deviceId,
            // Idempotency key: prevents duplicate locks from retries
            'idempotency_key': 'lock_${_tripId}_${seatPosition}_${userId ?? deviceId ?? _sessionId()}',
          },
        );

        // Handle error responses from server
        if (response.containsKey('code')) {
          final code = response['code'].toString();
          if (code == 'seat_already_locked') {
            throw SeatLockConflictException(
              response['detail']?.toString() ??
                  'Seat is locked by another counter.',
            );
          }
          if (code == 'seat_booked') {
            throw SeatLockConflictException(
              'This seat is already booked.',
            );
          }
          if (code == 'lock_expired') {
            throw SeatLockExpiredException();
          }
        }

        return SeatLock.fromJson(response);
      } on ApiException {
        // Retry on transient errors (network blips)
        if (_acquireRetries < _maxAcquireRetries - 1) {
          _acquireRetries++;
          await Future.delayed(Duration(
              milliseconds: 500 * _acquireRetries)); // 500ms, 1000ms
          continue;
        }
        rethrow;
      }
    }
    throw const ApiException('Failed to acquire seat lock after retries.');
  }

  /// Release the current lock via DELETE.
  ///
  /// Best-effort: if the API call fails, the server-side TTL will
  /// expire the lock automatically.
  Future<void> release() async {
    if (_currentLock == null) return;
    if (_releasing) return;
    await _doRelease();
  }

  Future<void> _doRelease() async {
    _releasing = true;
    notifyListeners();

    if (_currentLock?.id != null) {
      try {
        await _api.delete(
          '/organizations/$_orgId/seat-lock/${_currentLock!.id}/',
        );
      } on ApiException {
        // Best-effort: server-side TTL will clean up
      } catch (_) {}
    }

    _stopTtlTimer();
    if (_currentLock != null) {
      _pendingLocks.remove(_currentLock!.seatPosition);
    }
    _currentLock = null;
    _releasing = false;
    notifyListeners();
  }

  /// Extend the current lock TTL.
  Future<bool> extend() async {
    if (_currentLock?.id == null) return false;
    try {
      final result = await _api.post(
        '/organizations/$_orgId/seat-lock/${_currentLock!.id}/extend/',
        {},
      );
      _currentLock = SeatLock.fromJson(result);
      _startTtlTimer();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Called after successful booking — server has released the lock.
  void onBookingSuccess() {
    _stopTtlTimer();
    if (_currentLock != null) {
      _pendingLocks.remove(_currentLock!.seatPosition);
    }
    _currentLock = null;
    notifyListeners();
  }

  /// Called when the booking is cancelled or fails — release the lock.
  Future<void> onBookingCancelled() async {
    await release();
  }

  // ── Lock status polling ──────────────────────────────────────────

  /// Fetch all active locks for the current trip.
  ///
  /// Used to update seat availability when another counter may have
  /// locked or booked a seat.
  Future<List<SeatLock>> fetchTripLocks() async {
    try {
      final data = await _api.getList(
        '/organizations/$_orgId/seat-locks/?trip_id=$_tripId',
      );
      return data
          .whereType<Map<String, dynamic>>()
          .map(SeatLock.fromJson)
          .toList();
    } on ApiException {
      return [];
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────
  void _startTtlTimer() {
    _stopTtlTimer();
    _updateRemaining();
    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentLock == null) {
        _stopTtlTimer();
        return;
      }
      _updateRemaining();
      if (_currentLock!.expiresAt.isBefore(DateTime.now())) {
        if (_currentLock != null) {
          _pendingLocks.remove(_currentLock!.seatPosition);
        }
        _currentLock = null;
        _stopTtlTimer();
        notifyListeners();
      }
    });
  }

  void _updateRemaining() {
    _remaining =
        _currentLock != null ? _currentLock!.remaining : Duration.zero;
  }

  void _stopTtlTimer() {
    _ttlTimer?.cancel();
    _ttlTimer = null;
    _remaining = Duration.zero;
  }

  /// Format remaining time as MM:SS.
  String get remainingFormatted {
    if (_remaining <= Duration.zero) return 'Expired';
    final m = (_remaining.inMinutes).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Whether the lock is close to expiry (< 30 seconds).
  bool get isCloseToExpiry =>
      _currentLock != null &&
      _remaining > Duration.zero &&
      _remaining.inSeconds < 30;

  int _sessionCounter = 0;
  String _sessionId() {
    _sessionCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_sessionCounter';
  }

  @override
  void dispose() {
    _stopTtlTimer();
    if (_currentLock != null && _currentLock!.isValid) {
      _doRelease();
    }
    super.dispose();
  }
}

/// Thrown when a seat lock cannot be acquired because another user holds it.
class SeatLockConflictException implements Exception {
  final String message;
  const SeatLockConflictException(this.message);
}

/// Thrown when the acquired lock has expired.
class SeatLockExpiredException implements Exception {
  const SeatLockExpiredException();
}
