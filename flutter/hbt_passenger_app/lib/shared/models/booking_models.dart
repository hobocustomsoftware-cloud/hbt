/// Lightweight DTOs for passenger booking + ticket data.
library;

/// A booking confirmation as returned by `POST /passenger/bookings/`.
class BookingConfirmation {
  const BookingConfirmation({
    required this.id,
    required this.seat,
    required this.raw,
  });

  final String id;

  /// Seat label (may be null for pending/queue states).
  final String? seat;
  final Map<String, dynamic> raw;

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) =>
      BookingConfirmation(
        id: json['id']?.toString() ?? '',
        seat: json['seat']?.toString(),
        raw: json,
      );

  /// Short display id — safe truncation (never crashes on short ids).
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
}

/// A ticket as returned by `/passenger/tickets/`.
class TicketSummary {
  const TicketSummary({
    required this.id,
    required this.status,
    required this.raw,
  });

  final String id;
  final String status;
  final Map<String, dynamic> raw;

  factory TicketSummary.fromJson(Map<String, dynamic> json) => TicketSummary(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'unknown',
        raw: json,
      );
}
