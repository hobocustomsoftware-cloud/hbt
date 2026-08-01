import '../../shared/services/api_client.dart';
import '../../shared/models/ticket_validation_result.dart';

/// Validates tickets via QR code scanning.
///
/// Handles:
/// - QR parsing (HBT:TICKET: prefix stripping)
/// - API validation call
/// - Status derivation (valid, used, expired, cancelled, invalid)
/// - Error handling (network, API, parsing)
///
/// Designed to support offline validation in the future:
/// The [validate] method could check a local cache before the API call.
class TicketValidationService {
  TicketValidationService({
    required ApiClient api,
    required String organizationId,
  })  : _api = api,
        _orgId = organizationId;

  final ApiClient _api;
  final String _orgId;

  /// Parse a raw QR code value to extract the validation code.
  ///
  /// Returns the clean code and the document type.
  /// For ticket QR codes, strips the `HBT:TICKET:` prefix.
  /// For cargo QR codes, the full payload is used.
  static ParsedQrCode parseQrCode(String raw) {
    if (raw.startsWith('HBT:CARGO:V1:')) {
      return ParsedQrCode(
        code: raw,
        type: QrCodeType.cargo,
      );
    }
    if (raw.startsWith('HBT:TICKET:')) {
      return ParsedQrCode(
        code: raw.substring(11), // Strip "HBT:TICKET:"
        type: QrCodeType.ticket,
      );
    }
    // Fallback: treat as ticket code
    return ParsedQrCode(
      code: raw,
      type: QrCodeType.ticket,
    );
  }

  /// Validate a ticket by its QR code.
  ///
  /// Makes an API call to validate the ticket, parses the response,
  /// and returns a [TicketValidationResult] with the derived status.
  Future<TicketValidationResult> validate(String rawCode) async {
    final parsed = parseQrCode(rawCode);

    if (parsed.type == QrCodeType.cargo) {
      // Cargo QR — resolve via cargo endpoint
      return _validateCargo(parsed.code);
    }

    // Ticket QR — validate via ticket endpoint
    return _validateTicket(parsed.code);
  }

  /// Validate a ticket by its clean validation code.
  Future<TicketValidationResult> _validateTicket(String code) async {
    // Validate: code must not be empty or placeholder
    if (code.isEmpty || code == '***') {
      return TicketValidationResult.error('Invalid QR code value.');
    }

    try {
      final response = await _api.get(
        '/organizations/$_orgId/tickets/validate/?code=$code',
      );

      // Check for error in response
      if (response.containsKey('error') || response.containsKey('detail')) {
        final msg = response['error']?.toString() ??
            response['detail']?.toString() ??
            'Validation failed.';
        return TicketValidationResult.error(msg);
      }

      // Check for "not found" indicator
      if (response.containsKey('found') && response['found'] == false) {
        return TicketValidationResult.notFound();
      }

      if (response['ticket_number'] == null &&
          response['passenger_name'] == null) {
        return TicketValidationResult.notFound();
      }

      return TicketValidationResult.valid(response);
    } on ApiException catch (e) {
      // Map specific API error messages to validation statuses
      final msg = e.message.toLowerCase();
      if (msg.contains('not found') || msg.contains('invalid')) {
        return TicketValidationResult.error('Ticket not found.');
      }
      if (msg.contains('expired')) {
        return TicketValidationResult(
          isValid: false,
          status: TicketValidationStatus.expired,
          errorMessage: e.message,
        );
      }
      if (msg.contains('cancelled') || msg.contains('refunded')) {
        return TicketValidationResult(
          isValid: false,
          status: TicketValidationStatus.cancelled,
          errorMessage: e.message,
        );
      }
      if (msg.contains('already') && msg.contains('used')) {
        return TicketValidationResult(
          isValid: false,
          status: TicketValidationStatus.used,
          errorMessage: e.message,
        );
      }
      return TicketValidationResult.error(e.message);
    } catch (e) {
      return TicketValidationResult.error('Unexpected error: $e');
    }
  }

  /// Validate a cargo QR code.
  Future<TicketValidationResult> _validateCargo(String code) async {
    try {
      final response = await _api.post(
        '/organizations/$_orgId/cargo/qr/resolve/',
        {'qr_payload': code},
      );
      if (response['shipment_number'] == null) {
        return TicketValidationResult.notFound();
      }
      // Cargo validation always returns as "valid" for display
      return TicketValidationResult.valid(response);
    } on ApiException catch (e) {
      return TicketValidationResult.error(e.message);
    } catch (e) {
      return TicketValidationResult.error('Unexpected error: $e');
    }
  }

  /// Build a display-friendly result text from validation data.
  static String formatResult(TicketValidationResult result) {
    if (result.errorMessage != null && result.ticketData == null) {
      return result.errorMessage!;
    }

    final data = result.ticketData;
    if (data == null) return 'No ticket data.';

    final buffer = StringBuffer();
    buffer.writeln(result.status.label);
    buffer.writeln('');

    if (data['passenger_name'] != null) {
      buffer.writeln('Passenger: ${data['passenger_name']}');
    }
    if (data['ticket_number'] != null) {
      buffer.writeln('Ticket: ${data['ticket_number']}');
    }
    if (data['trip_number'] != null) {
      buffer.writeln('Trip: ${data['trip_number']}');
    }
    if (data['planned_departure_at'] != null) {
      buffer.writeln('Departure: ${data['planned_departure_at']}');
    }
    if (data['seat_identifier'] != null) {
      buffer.writeln('Seat: ${data['seat_identifier']}');
    }
    if (data['total_amount'] != null) {
      buffer.writeln('Fare: ${data['total_amount']} MMK');
    }

    return buffer.toString();
  }
}

/// Parsed QR code information.
class ParsedQrCode {
  final String code;
  final QrCodeType type;

  const ParsedQrCode({required this.code, required this.type});
}

/// Type of document identified by the QR code.
enum QrCodeType { ticket, cargo }
