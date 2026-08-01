import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_passenger_app/core/validation/validators.dart';

void main() {
  group('validateMyanmarPhone', () {
    test('accepts local 09 format', () {
      expect(validateMyanmarPhone('09123456789'), isNull);
      expect(validateMyanmarPhone('09 123 456 789'), isNull);
      expect(validateMyanmarPhone('09-123456789'), isNull);
    });

    test('accepts international +95 format', () {
      expect(validateMyanmarPhone('+959123456789'), isNull);
      expect(validateMyanmarPhone('959123456789'), isNull);
    });

    test('rejects invalid formats', () {
      expect(validateMyanmarPhone('12345'), isNotNull);
      expect(validateMyanmarPhone('09123'), isNotNull);
      expect(validateMyanmarPhone('+959123456789012345'), isNotNull);
      expect(validateMyanmarPhone('08123456789'), isNotNull);
    });

    test('handles empty values', () {
      expect(validateMyanmarPhone(''), isNotNull);
      expect(validateMyanmarPhone('', required: false), isNull);
      expect(validateMyanmarPhone(null), isNotNull);
    });
  });

  group('validatePassword', () {
    test('requires at least 8 characters', () {
      expect(validatePassword('1234567'), isNotNull);
      expect(validatePassword('12345678'), isNull);
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('', required: false), isNull);
    });
  });

  group('validateOptionalName', () {
    test('optional but must be 2+ chars when provided', () {
      expect(validateOptionalName(''), isNull);
      expect(validateOptionalName('A'), isNotNull);
      expect(validateOptionalName('Ko Ko'), isNull);
    });
  });
}
