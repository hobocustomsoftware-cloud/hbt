import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/models/ticket_validation_result.dart';
import 'package:hbt_business_app/shared/services/ticket_validation_service.dart';

void main() {
  group('TicketValidationService.parseQrCode', () {
    test('parses HBT:TICKET: prefixed code', () {
      final result = TicketValidationService.parseQrCode('HBT:TICKET:ABC123');
      expect(result.type, QrCodeType.ticket);
      expect(result.code, 'ABC123');
    });

    test('parses HBT:CARGO:V1: prefixed code', () {
      final result = TicketValidationService.parseQrCode('HBT:CARGO:V1:SHIP001');
      expect(result.type, QrCodeType.cargo);
      expect(result.code, 'HBT:CARGO:V1:SHIP001');
    });

    test('parses plain code as ticket', () {
      final result = TicketValidationService.parseQrCode('VALID-CODE-123');
      expect(result.type, QrCodeType.ticket);
      expect(result.code, 'VALID-CODE-123');
    });

    test('parses empty string as ticket', () {
      final result = TicketValidationService.parseQrCode('');
      expect(result.type, QrCodeType.ticket);
      expect(result.code, '');
    });
  });

  group('TicketValidationResult', () {
    test('valid ticket derives valid status', () {
      final result = TicketValidationResult.valid({
        'ticket_number': 'TKT-001',
        'passenger_name': 'Mg Mg',
        'status': 'issued',
      });
      expect(result.isValid, true);
      expect(result.status, TicketValidationStatus.valid);
    });

    test('validated ticket derives used status', () {
      final result = TicketValidationResult.valid({
        'ticket_number': 'TKT-001',
        'status': 'validated',
      });
      expect(result.isValid, true);
      expect(result.status, TicketValidationStatus.used);
    });

    test('expired ticket derives expired status', () {
      final result = TicketValidationResult.valid({
        'ticket_number': 'TKT-001',
        'status': 'expired',
      });
      expect(result.isValid, true);
      expect(result.status, TicketValidationStatus.expired);
    });

    test('cancelled ticket derives cancelled status', () {
      final result = TicketValidationResult.valid({
        'ticket_number': 'TKT-001',
        'status': 'cancelled',
      });
      expect(result.isValid, true);
      expect(result.status, TicketValidationStatus.cancelled);
    });

    test('refunded ticket derives cancelled status', () {
      final result = TicketValidationResult.valid({
        'ticket_number': 'TKT-001',
        'status': 'refunded',
      });
      expect(result.isValid, true);
      expect(result.status, TicketValidationStatus.cancelled);
    });

    test('boarded ticket derives used status', () {
      final result = TicketValidationResult.valid({
        'ticket_number': 'TKT-001',
        'status': 'boarded',
      });
      expect(result.isValid, true);
      expect(result.status, TicketValidationStatus.used);
    });

    test('notFound result has invalid status', () {
      final result = TicketValidationResult.notFound();
      expect(result.isValid, false);
      expect(result.status, TicketValidationStatus.invalid);
      expect(result.errorMessage, isNotNull);
    });

    test('error result has error status', () {
      final result = TicketValidationResult.error('Network error');
      expect(result.isValid, false);
      expect(result.status, TicketValidationStatus.error);
      expect(result.errorMessage, 'Network error');
    });

    test('offline result has offline status', () {
      final result = TicketValidationResult.offline({
        'ticket_number': 'TKT-001',
      });
      expect(result.isValid, false);
      expect(result.status, TicketValidationStatus.offline);
    });
  });

  group('TicketValidationStatus', () {
    test('valid status is actionable', () {
      expect(TicketValidationStatus.valid.isActionable, true);
      expect(TicketValidationStatus.used.isActionable, false);
      expect(TicketValidationStatus.expired.isActionable, false);
    });

    test('used status is a warning', () {
      expect(TicketValidationStatus.used.isWarning, true);
      expect(TicketValidationStatus.valid.isWarning, false);
    });

    test('expired/cancelled/invalid are blocking', () {
      expect(TicketValidationStatus.expired.isBlocking, true);
      expect(TicketValidationStatus.cancelled.isBlocking, true);
      expect(TicketValidationStatus.invalid.isBlocking, true);
      expect(TicketValidationStatus.valid.isBlocking, false);
    });

    test('labels are non-empty for all statuses', () {
      for (final status in TicketValidationStatus.values) {
        expect(status.label.isNotEmpty, true);
      }
    });
  });
}
