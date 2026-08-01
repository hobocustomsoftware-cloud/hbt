/// Result of a ticket validation lookup.
class TicketValidationResult {
  final bool isValid;
  final TicketValidationStatus status;
  final Map<String, dynamic>? ticketData;
  final String? errorMessage;

  const TicketValidationResult({
    required this.isValid,
    required this.status,
    this.ticketData,
    this.errorMessage,
  });

  /// Build a success result from valid ticket data.
  factory TicketValidationResult.valid(Map<String, dynamic> data) =>
      TicketValidationResult(
        isValid: true,
        status: _deriveStatus(data),
        ticketData: data,
      );

  /// Build an error result from an API exception or network error.
  factory TicketValidationResult.error(String message) =>
      TicketValidationResult(
        isValid: false,
        status: TicketValidationStatus.error,
        errorMessage: message,
      );

  /// Build a result for ticket-not-found response.
  factory TicketValidationResult.notFound() =>
      TicketValidationResult(
        isValid: false,
        status: TicketValidationStatus.invalid,
        errorMessage: 'Ticket not found.',
      );

  /// Build a cached result for offline validation (stub — not implemented).
  factory TicketValidationResult.offline(Map<String, dynamic> data) =>
      TicketValidationResult(
        isValid: false,
        status: TicketValidationStatus.offline,
        ticketData: data,
        errorMessage: 'Offline mode: result may be stale.',
      );

  static TicketValidationStatus _deriveStatus(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    switch (status) {
      case 'issued':
        return TicketValidationStatus.valid;
      case 'validated':
        return TicketValidationStatus.used;
      case 'used':
      case 'boarded':
        return TicketValidationStatus.used;
      case 'expired':
        return TicketValidationStatus.expired;
      case 'cancelled':
      case 'canceled':
      case 'refunded':
        return TicketValidationStatus.cancelled;
      default:
        return TicketValidationStatus.valid;
    }
  }
}

/// Possible statuses returned by ticket validation.
enum TicketValidationStatus {
  /// Ticket is valid and ready for use.
  valid,

  /// Ticket has already been used / scanned / boarded.
  used,

  /// Ticket has expired (trip departure has passed).
  expired,

  /// Ticket has been cancelled or refunded.
  cancelled,

  /// QR code is not associated with any valid ticket.
  invalid,

  /// Validation failed due to network error or server error.
  error,

  /// Validation performed from offline cache (stale data).
  offline;

  String get label {
    switch (this) {
      case TicketValidationStatus.valid:
        return '✅ Valid — Ticket ready for check-in';
      case TicketValidationStatus.used:
        return '⚠️ Already Used — This ticket has already been validated';
      case TicketValidationStatus.expired:
        return '❌ Expired — Trip departure has passed';
      case TicketValidationStatus.cancelled:
        return '❌ Cancelled — This ticket has been refunded/cancelled';
      case TicketValidationStatus.invalid:
        return '❌ Invalid — No matching ticket found';
      case TicketValidationStatus.error:
        return '⚠️ Error — Unable to validate';
      case TicketValidationStatus.offline:
        return '⚠️ Offline — Result may be stale';
    }
  }

  bool get isActionable =>
      this == TicketValidationStatus.valid;

  bool get isWarning =>
      this == TicketValidationStatus.used || this == TicketValidationStatus.offline;

  bool get isBlocking =>
      this == TicketValidationStatus.expired ||
      this == TicketValidationStatus.cancelled ||
      this == TicketValidationStatus.invalid;
}
