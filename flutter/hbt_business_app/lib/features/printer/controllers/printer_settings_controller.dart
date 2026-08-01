import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/models/printer_models.dart';

/// Manages printer settings: default printer, paper size, recently used.
///
/// Settings are persisted to [FlutterSecureStorage] and survive app restarts.
class PrinterSettingsController extends ChangeNotifier {
  PrinterSettingsController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _defaultPrinterIdKey = 'hbt_default_printer_id';
  static const _defaultPrinterNameKey = 'hbt_default_printer_name';
  static const _defaultPaperWidthKey = 'hbt_default_paper_width';
  static const _autoconnectKey = 'hbt_printer_autoconnect';
  static const _copiesKey = 'hbt_default_copies';

  String? _defaultPrinterId;
  String? _defaultPrinterName;
  PaperWidth _defaultPaperWidth = PaperWidth.mm80;
  bool _autoconnect = true;
  int _defaultCopies = 1;

  /// Cached known printers (discovered + saved).
  final List<PrinterDevice> _savedPrinters = [];

  /// Last printed document data (for reprint).
  Map<String, dynamic>? _lastPrintData;
  PrintDocumentType? _lastPrintType;

  // ── Getters ──
  String? get defaultPrinterId => _defaultPrinterId;
  String? get defaultPrinterName => _defaultPrinterName;
  PaperWidth get defaultPaperWidth => _defaultPaperWidth;
  bool get autoconnect => _autoconnect;
  int get defaultCopies => _defaultCopies;
  List<PrinterDevice> get savedPrinters => List.unmodifiable(_savedPrinters);
  Map<String, dynamic>? get lastPrintData => _lastPrintData;
  PrintDocumentType? get lastPrintType => _lastPrintType;
  bool get hasLastPrint => _lastPrintData != null;

  /// Restore saved settings on app startup.
  Future<void> restore() async {
    _defaultPrinterId = await _storage.read(key: _defaultPrinterIdKey);
    _defaultPrinterName = await _storage.read(key: _defaultPrinterNameKey);

    final widthStr = await _storage.read(key: _defaultPaperWidthKey);
    if (widthStr != null) {
      _defaultPaperWidth = PaperWidth.values.firstWhere(
        (p) => p.name == widthStr,
        orElse: () => PaperWidth.mm80,
      );
    }

    final autoStr = await _storage.read(key: _autoconnectKey);
    _autoconnect = autoStr != 'false';

    final copiesStr = await _storage.read(key: _copiesKey);
    _defaultCopies = int.tryParse(copiesStr ?? '') ?? 1;

    notifyListeners();
  }

  /// Set the default printer.
  Future<void> setDefaultPrinter(PrinterDevice device) async {
    _defaultPrinterId = device.id;
    _defaultPrinterName = device.name;

    await _storage.write(key: _defaultPrinterIdKey, value: device.id);
    await _storage.write(key: _defaultPrinterNameKey, value: device.name);

    // Add to saved printers if not already present
    if (!_savedPrinters.any((p) => p.id == device.id)) {
      _savedPrinters.add(device);
    }

    notifyListeners();
  }

  /// Clear the default printer.
  Future<void> clearDefaultPrinter() async {
    _defaultPrinterId = null;
    _defaultPrinterName = null;
    await _storage.delete(key: _defaultPrinterIdKey);
    await _storage.delete(key: _defaultPrinterNameKey);
    notifyListeners();
  }

  /// Set the default paper width.
  Future<void> setDefaultPaperWidth(PaperWidth width) async {
    _defaultPaperWidth = width;
    await _storage.write(key: _defaultPaperWidthKey, value: width.name);
    notifyListeners();
  }

  /// Set auto-connect on app startup.
  Future<void> setAutoconnect(bool value) async {
    _autoconnect = value;
    await _storage.write(key: _autoconnectKey, value: value.toString());
    notifyListeners();
  }

  /// Set default number of copies.
  Future<void> setDefaultCopies(int copies) async {
    _defaultCopies = copies.clamp(1, 5);
    await _storage.write(
        key: _copiesKey, value: _defaultCopies.toString());
    notifyListeners();
  }

  /// Save a printer for future use (add to saved printers list).
  Future<void> savePrinter(PrinterDevice device) async {
    if (!_savedPrinters.any((p) => p.id == device.id)) {
      _savedPrinters.add(device);
      notifyListeners();
    }
  }

  /// Remove a printer from the saved list.
  void forgetPrinter(String printerId) {
    _savedPrinters.removeWhere((p) => p.id == printerId);
    if (_defaultPrinterId == printerId) {
      clearDefaultPrinter();
    }
    notifyListeners();
  }

  /// Record the last printed document for reprint.
  void recordLastPrint(
      PrintDocumentType type, Map<String, dynamic> data) {
    _lastPrintType = type;
    _lastPrintData = Map<String, dynamic>.from(data);
    notifyListeners();
  }

  /// Clear the last print record.
  void clearLastPrint() {
    _lastPrintType = null;
    _lastPrintData = null;
    notifyListeners();
  }

}
