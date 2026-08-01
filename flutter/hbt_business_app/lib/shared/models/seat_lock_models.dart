/// Status of a seat lock.
enum SeatLockStatus {
  /// Seat is available — no active lock.
  available,

  /// Seat is held by the current device/user.
  held,

  /// Seat is held by another device/user.
  locked,

  /// Seat has been booked.
  booked;

  String get apiValue => name;

  static SeatLockStatus fromString(String value) =>
      SeatLockStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => SeatLockStatus.available,
      );
}

/// A seat lock record representing a hold on a specific seat.
///
/// When a counter staff selects a seat, a lock is acquired. The lock has
/// a TTL (default 5 minutes). If the booking is not completed within the
/// TTL, the lock expires and the seat becomes available again.
class SeatLock {
  final String? id;
  final String tripId;
  final String seatPosition;
  final String? heldByDeviceId;
  final String? heldByUserId;
  final DateTime heldAt;
  final DateTime expiresAt;
  final String status;

  const SeatLock({
    this.id,
    required this.tripId,
    required this.seatPosition,
    this.heldByDeviceId,
    this.heldByUserId,
    required this.heldAt,
    required this.expiresAt,
    this.status = 'active',
  });

  /// Whether this lock is still valid.
  bool get isValid => status == 'active' && expiresAt.isAfter(DateTime.now());

  /// Remaining duration before the lock expires.
  Duration get remaining => expiresAt.difference(DateTime.now());

  /// Whether this lock is held by a specific device.
  bool isHeldByDevice(String deviceId) => heldByDeviceId == deviceId;

  /// Whether this lock is held by a specific user.
  bool isHeldByUser(String userId) => heldByUserId == userId;

  factory SeatLock.fromJson(Map<String, dynamic> json) => SeatLock(
        id: json['id']?.toString(),
        tripId: json['trip_id']?.toString() ?? '',
        seatPosition: json['seat_position']?.toString() ?? '',
        heldByDeviceId: json['held_by_device_id']?.toString(),
        heldByUserId: json['held_by_user_id']?.toString(),
        heldAt: DateTime.tryParse(json['held_at']?.toString() ?? '') ??
            DateTime.now(),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
            DateTime.now(),
        status: json['status']?.toString() ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'trip_id': tripId,
        'seat_position': seatPosition,
        if (heldByDeviceId != null) 'held_by_device_id': heldByDeviceId,
        if (heldByUserId != null) 'held_by_user_id': heldByUserId,
        'held_at': heldAt.toUtc().toIso8601String(),
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'status': status,
      };
}

/// Extended seat data with lock information returned by the seats API.
///
/// The API response for each seat includes availability and an optional
/// lock payload when the seat is held.
class SeatWithLock {
  final String id;
  final String identifier;
  final String? row;
  final String? col;
  final bool available;
  final SeatLock? activeLock;

  const SeatWithLock({
    required this.id,
    required this.identifier,
    this.row,
    this.col,
    required this.available,
    this.activeLock,
  });

  /// Composite status derived from availability and lock state.
  SeatLockStatus get lockStatus {
    if (!available) return SeatLockStatus.booked;
    if (activeLock != null && activeLock!.isValid) return SeatLockStatus.locked;
    return SeatLockStatus.available;
  }

  factory SeatWithLock.fromJson(Map<String, dynamic> json) => SeatWithLock(
        id: json['id']?.toString() ?? '',
        identifier: json['identifier']?.toString() ?? '',
        row: json['row']?.toString(),
        col: json['col']?.toString(),
        available: json['available'] == true,
        activeLock: json['active_lock'] != null
            ? SeatLock.fromJson(
                json['active_lock'] as Map<String, dynamic>)
            : null,
      );
}
