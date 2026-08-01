/// Lightweight DTOs for passenger trip data.
///
/// These mirror the API response shapes the passenger app already consumes
/// (previously parsed inline as `Map<String, dynamic>` in screens). Parsing
/// moves into repositories; DTOs are immutable and tolerate missing fields.
library;

/// A trip summary as returned by `/passenger/trips/search/`.
class TripSummary {
  const TripSummary({
    required this.id,
    required this.tripNumber,
    required this.organizationName,
    required this.plannedDepartureAt,
    required this.raw,
  });

  final String id;
  final String tripNumber;
  final String organizationName;

  /// ISO-8601 departure timestamp (may be null in API responses).
  final String? plannedDepartureAt;

  /// The full original payload (screens still read extra fields).
  final Map<String, dynamic> raw;

  factory TripSummary.fromJson(Map<String, dynamic> json) => TripSummary(
        id: json['id']?.toString() ?? '',
        tripNumber: json['trip_number']?.toString() ?? 'Trip',
        organizationName:
            json['organization_name']?.toString() ?? 'Bus Co.',
        plannedDepartureAt: json['planned_departure_at']?.toString(),
        raw: json,
      );

  /// Human-friendly departure display, e.g. `2026-08-01 09:30`.
  String get departureLabel {
    final dt = plannedDepartureAt;
    if (dt == null || dt.isEmpty) return '-';
    final trimmed = dt.length > 16 ? dt.substring(0, 16) : dt;
    return trimmed.replaceAll('T', ' ');
  }
}

/// A single trip detail as returned by `/passenger/trips/{id}/`.
class TripDetail {
  const TripDetail({
    required this.id,
    required this.raw,
  });

  final String id;
  final Map<String, dynamic> raw;

  factory TripDetail.fromJson(Map<String, dynamic> json) => TripDetail(
        id: json['id']?.toString() ?? '',
        raw: json,
      );

  String get tripNumber => raw['trip_number']?.toString() ?? 'Trip';
  String get organizationName =>
      raw['organization_name']?.toString() ?? 'Bus Co.';
  String? get plannedDepartureAt => raw['planned_departure_at']?.toString();
}

/// A seat as returned by `/passenger/trips/{id}/seats/`.
class SeatInfo {
  const SeatInfo({
    required this.id,
    required this.label,
    required this.isAvailable,
    required this.raw,
  });

  final String id;
  final String label;

  /// False when the seat is booked or held by another passenger.
  final bool isAvailable;
  final Map<String, dynamic> raw;

  factory SeatInfo.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final activeLock = json['active_lock'];
    final available = status == null || status == 'available';
    return SeatInfo(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['seat_number']?.toString() ?? '',
      isAvailable: available && activeLock == null,
      raw: json,
    );
  }
}

/// Safe list extraction handling `{'results': [...]}` and bare arrays.
List<Map<String, dynamic>> extractMapList(dynamic response) {
  final List<dynamic> raw;
  if (response is List<dynamic>) {
    raw = response;
  } else if (response is Map<String, dynamic>) {
    final results = response['results'];
    if (results is List<dynamic>) {
      raw = results;
    } else {
      return <Map<String, dynamic>>[];
    }
  } else {
    return <Map<String, dynamic>>[];
  }
  return raw.whereType<Map<String, dynamic>>().toList();
}
