/// Shared input validators for the passenger app.
///
/// Myanmar phone numbers: local format `09XXXXXXXXX` (9–11 digits after
/// the leading `09`), optionally with a `+95` country prefix. Digits are
/// separated out so `+95 9 123456789` and `09 123456789` both validate.
library;

/// Accepts `09...` (local) or `+959...` / `959...` (international) forms.
final RegExp _phoneRegex = RegExp(r'^(?:\+?95|0)?9\d{7,9}$');

/// Validate a Myanmar phone number. Returns an error message, or null if
/// the value is valid (empty values are handled by the `required` flag).
String? validateMyanmarPhone(String? value, {bool required = true}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return required ? 'Phone number is required.' : null;
  }
  // Strip spaces and dashes for validation (09 123 456 789, +95-9-...).
  final digits = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
  if (!_phoneRegex.hasMatch(digits)) {
    return 'Enter a valid Myanmar phone number (e.g. 09123456789).';
  }
  return null;
}

/// Password policy: at least 8 characters (matches registration backend).
String? validatePassword(String? value, {bool required = true}) {
  final v = value ?? '';
  if (v.isEmpty) return required ? 'Password is required.' : null;
  if (v.length < 8) return 'Password must be at least 8 characters.';
  return null;
}

/// Name fields: optional, but if present must be non-empty after trim.
String? validateOptionalName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (trimmed.length < 2) return 'Name must be at least 2 characters.';
  return null;
}
