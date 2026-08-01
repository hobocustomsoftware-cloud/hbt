import 'dart:convert';

import '../../../shared/models/printer_models.dart';

/// Builds ESC/POS byte sequences for HBT document templates.
///
/// Each template produces a list of bytes that can be sent directly to
/// a thermal printer supporting ESC/POS (Epson, Star, Bixolon, etc.).
class PrintTemplateBuilder {
  const PrintTemplateBuilder._();

  // ── ESC/POS constants ─────────────────────────────────────────────
  static const _esc = 0x1B;
  static const _gs = 0x1D;
  static const _lf = 0x0A;

  static List<int> _init() =>
      [_esc, 0x40]; // ESC @ — initialise printer
  static List<int> _lineFeed([int n = 1]) =>
      List.filled(n, _lf);
  static List<int> _alignCenter() =>
      [_esc, 0x61, 0x01]; // ESC a 1
  static List<int> _alignLeft() =>
      [_esc, 0x61, 0x00]; // ESC a 0
  static List<int> _bold(bool on) =>
      [_esc, 0x45, on ? 0x01 : 0x00]; // ESC E n
  static List<int> _doubleHw() =>
      [_gs, 0x21, 0x33]; // GS ! 0x33 — double height + width
  static List<int> _normalSize() =>
      [_gs, 0x21, 0x00]; // GS ! 0x00 — normal
  static List<int> _cut() =>
      [_gs, 0x56, 0x00]; // GS V 0 — full cut

  static List<int> _text(String s) =>
      utf8.encode(s) + [_lf];

  static List<int> _divider(int width, {String char = '─'}) {
    return _text(char * width);
  }

  static List<int> _blankLine([int n = 1]) => _lineFeed(n);

  // ── Public builders ───────────────────────────────────────────────

  /// Build a ticket print document.
  static List<int> buildTicket(Map<String, dynamic> data,
      {PaperWidth width = PaperWidth.mm80}) {
    final w = width.widthChars;
    final bytes = <int>[..._init(), ..._blankLine()];

    // Header
    bytes
      ..addAll(_alignCenter())
      ..addAll(_doubleHw())
      ..addAll(_text(data['company_name']?.toString() ?? 'HBT Bus'))
      ..addAll(_normalSize())
      ..addAll(_bold(true))
      ..addAll(_text('TICKET'))
      ..addAll(_bold(false))
      ..addAll(_text(data['branch_name']?.toString() ?? ''))
      ..addAll(_text(data['counter_name']?.toString() ?? ''))
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_blankLine());

    // Body
    bytes
      ..addAll(_alignLeft())
      ..addAll(_bold(true))
      ..addAll(_text('Ticket: ${data['ticket_number'] ?? '-'}'))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_infoRow('Passenger', data['passenger_name']?.toString(), w))
      ..addAll(_infoRow('Trip', data['trip_number']?.toString(), w))
      ..addAll(_infoRow('Date', data['service_date']?.toString(), w))
      ..addAll(_infoRow('Departure', data['departure_time']?.toString(), w))
      ..addAll(_infoRow('Seat', data['seat_number']?.toString(), w))
      ..addAll(_infoRow('Pickup', data['pickup_stop']?.toString(), w))
      ..addAll(_infoRow('Dropoff', data['dropoff_stop']?.toString(), w));

    // Fare
    bytes
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_infoRow('Fare', data['fare_amount']?.toString(), w))
      ..addAll(_infoRow('Service Charge', data['service_charge']?.toString(), w))
      ..addAll(_bold(true))
      ..addAll(_infoRow('Total', data['total_amount']?.toString(), w))
      ..addAll(_bold(false));

    // Footer
    bytes
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_alignCenter())
      ..addAll(_text('Thank you for travelling with us!'))
      ..addAll(_text(data['validation_code']?.toString() ?? ''))
      ..addAll(_blankLine(2))
      ..addAll(_cut());

    return bytes;
  }

  /// Build a cargo receipt print document.
  static List<int> buildCargoReceipt(Map<String, dynamic> data,
      {PaperWidth width = PaperWidth.mm80}) {
    final w = width.widthChars;
    final bytes = <int>[..._init(), ..._blankLine()];

    bytes
      ..addAll(_alignCenter())
      ..addAll(_doubleHw())
      ..addAll(_text(data['company_name']?.toString() ?? 'HBT Bus'))
      ..addAll(_normalSize())
      ..addAll(_bold(true))
      ..addAll(_text('CARGO RECEIPT'))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_blankLine())
      ..addAll(_alignLeft())
      ..addAll(_bold(true))
      ..addAll(_text('Shipment: ${data['shipment_number'] ?? '-'}'))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_infoRow('Tracking', data['tracking_code']?.toString(), w))
      ..addAll(_infoRow('Sender', data['sender_name']?.toString(), w))
      ..addAll(_infoRow('Receiver', data['receiver_name']?.toString(), w))
      ..addAll(_infoRow('Origin', data['origin_terminal']?.toString(), w))
      ..addAll(_infoRow('Destination', data['destination_terminal']?.toString(), w))
      ..addAll(_infoRow('Category', data['item_category']?.toString(), w))
      ..addAll(_infoRow('Pieces', data['piece_count']?.toString(), w))
      ..addAll(_infoRow('Weight', data['weight_kg']?.toString(), w))
      ..addAll(_blankLine())
      ..addAll(_bold(true))
      ..addAll(_infoRow('Total Charge', data['total_charge']?.toString(), w))
      ..addAll(_bold(false));

    bytes
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_alignCenter())
      ..addAll(_text('Received in good condition'))
      ..addAll(_blankLine(2))
      ..addAll(_cut());

    return bytes;
  }

  /// Build a refund receipt print document.
  static List<int> buildRefundReceipt(Map<String, dynamic> data,
      {PaperWidth width = PaperWidth.mm80}) {
    final w = width.widthChars;
    final bytes = <int>[..._init(), ..._blankLine()];

    bytes
      ..addAll(_alignCenter())
      ..addAll(_doubleHw())
      ..addAll(_text(data['company_name']?.toString() ?? 'HBT Bus'))
      ..addAll(_normalSize())
      ..addAll(_bold(true))
      ..addAll(_text('REFUND RECEIPT'))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_blankLine())
      ..addAll(_alignLeft())
      ..addAll(_bold(true))
      ..addAll(_text('Refund: ${data['refund_number'] ?? '-'}'))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_infoRow('Passenger', data['passenger_name']?.toString(), w))
      ..addAll(_infoRow('Booking', data['booking_number']?.toString(), w))
      ..addAll(_infoRow('Ticket', data['ticket_number']?.toString(), w))
      ..addAll(_infoRow('Payment', data['payment_reference']?.toString(), w))
      ..addAll(_infoRow('Reason', data['reason']?.toString(), w))
      ..addAll(_blankLine())
      ..addAll(_bold(true))
      ..addAll(_infoRow('Refund Amount', data['refund_amount']?.toString(), w))
      ..addAll(_bold(false))
      ..addAll(_infoRow('Method', data['refund_method']?.toString(), w))
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_alignCenter())
      ..addAll(_text('Processed at ${data['counter_name'] ?? ""}'))
      ..addAll(_blankLine(2))
      ..addAll(_cut());

    return bytes;
  }

  /// Build a shift summary print document.
  static List<int> buildShiftSummary(Map<String, dynamic> data,
      {PaperWidth width = PaperWidth.mm80}) {
    final w = width.widthChars;
    final bytes = <int>[..._init(), ..._blankLine()];

    bytes
      ..addAll(_alignCenter())
      ..addAll(_doubleHw())
      ..addAll(_text(data['company_name']?.toString() ?? 'HBT Bus'))
      ..addAll(_normalSize())
      ..addAll(_bold(true))
      ..addAll(_text('SHIFT SUMMARY'))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_blankLine())
      ..addAll(_alignLeft())
      ..addAll(_text('Branch: ${data['branch_name'] ?? '-'}'))
      ..addAll(_text('Counter: ${data['counter_name'] ?? '-'}'))
      ..addAll(_text('Staff: ${data['staff_name'] ?? '-'}'))
      ..addAll(_text('Date: ${data['date'] ?? '-'}'))
      ..addAll(_text('Duration: ${data['duration'] ?? '-'}'))
      ..addAll(_blankLine())
      ..addAll(_divider(w))
      ..addAll(_blankLine())
      ..addAll(_bold(true))
      ..addAll(_text('CASH'))
      ..addAll(_bold(false))
      ..addAll(_infoRow('Opening', data['opening_cash']?.toString(), w))
      ..addAll(_infoRow('Expected', data['expected_cash']?.toString(), w))
      ..addAll(_infoRow('Actual', data['actual_cash']?.toString(), w))
      ..addAll(_infoRow('Difference', data['cash_difference']?.toString(), w))
      ..addAll(_blankLine())
      ..addAll(_bold(true))
      ..addAll(_text('REVENUE'))
      ..addAll(_bold(false))
      ..addAll(_infoRow('Ticket Sales', data['ticket_revenue']?.toString(), w))
      ..addAll(_infoRow('Cargo Revenue', data['cargo_revenue']?.toString(), w))
      ..addAll(_infoRow('Expenses', data['expense_total']?.toString(), w))
      ..addAll(_bold(true))
      ..addAll(_infoRow('Net Revenue', data['net_revenue']?.toString(), w))
      ..addAll(_bold(false))
      ..addAll(_blankLine())
      ..addAll(_bold(true))
      ..addAll(_text('ACTIVITY'))
      ..addAll(_bold(false))
      ..addAll(_infoRow('Tickets', data['ticket_count']?.toString(), w))
      ..addAll(_infoRow('Cargo', data['cargo_count']?.toString(), w))
      ..addAll(_infoRow('Refunds', data['refund_count']?.toString(), w))
      ..addAll(_infoRow('Expenses', data['expense_count']?.toString(), w));

    bytes
      ..addAll(_blankLine(2))
      ..addAll(_alignCenter())
      ..addAll(_text('--- End of Shift ---'))
      ..addAll(_blankLine(2))
      ..addAll(_cut());

    return bytes;
  }

  // ── Helpers ────────────────────────────────────────────────────────
  static List<int> _infoRow(String label, String? value, int width) {
    final v = value ?? '-';
    final padded = '$label: $v';
    final truncated = padded.length > width
        ? '${padded.substring(0, width - 3)}...'
        : padded;
    return _text(truncated);
  }
}
