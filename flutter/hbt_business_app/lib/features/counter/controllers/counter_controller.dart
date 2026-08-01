import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the active counter identity for the current work session.
///
/// The active counter is set when a shift is opened and cleared when
/// the shift is closed. All operations (ticket sales, cargo, refunds,
/// expenses) are tagged with the active counter identity.
class CounterController extends ChangeNotifier {
  CounterController({required this.storage});

  final FlutterSecureStorage storage;
  static const _counterIdKey = 'hbt_active_counter_id';
  static const _branchIdKey = 'hbt_active_branch_id';
  static const _branchNameKey = 'hbt_active_branch_name';
  static const _counterNameKey = 'hbt_active_counter_name';

  String? _branchId;
  String? _branchName;
  String? _counterId;
  String? _counterName;

  /// The active branch ID.
  String? get branchId => _branchId;

  /// The active branch display name.
  String? get branchName => _branchName;

  /// The active counter ID.
  String? get counterId => _counterId;

  /// The active counter display name.
  String? get counterName => _counterName;

  /// Whether a counter is currently active.
  bool get hasActiveCounter => _counterId != null;

  /// Restore persisted counter identity on app startup.
  Future<void> restore() async {
    _counterId = await storage.read(key: _counterIdKey);
    _branchId = await storage.read(key: _branchIdKey);
    _branchName = await storage.read(key: _branchNameKey);
    _counterName = await storage.read(key: _counterNameKey);
    notifyListeners();
  }

  /// Set the active counter (called when a shift is opened).
  Future<void> setActiveCounter({
    required String branchId,
    required String branchName,
    required String counterId,
    required String counterName,
  }) async {
    _branchId = branchId;
    _branchName = branchName;
    _counterId = counterId;
    _counterName = counterName;

    await storage.write(key: _branchIdKey, value: branchId);
    await storage.write(key: _branchNameKey, value: branchName);
    await storage.write(key: _counterIdKey, value: counterId);
    await storage.write(key: _counterNameKey, value: counterName);
    notifyListeners();
  }

  /// Clear the active counter (called when shift is closed or on sign-out).
  Future<void> clear() async {
    _branchId = null;
    _branchName = null;
    _counterId = null;
    _counterName = null;

    await storage.delete(key: _branchIdKey);
    await storage.delete(key: _branchNameKey);
    await storage.delete(key: _counterIdKey);
    await storage.delete(key: _counterNameKey);
    notifyListeners();
  }

  /// Audit context map for recording operations.
  Map<String, dynamic> get auditContext {
    if (!hasActiveCounter) return {};
    return {
      'branch_id': _branchId,
      'counter_id': _counterId,
      if (_branchName != null) 'branch_name': _branchName,
      if (_counterName != null) 'counter_name': _counterName,
    };
  }
}
