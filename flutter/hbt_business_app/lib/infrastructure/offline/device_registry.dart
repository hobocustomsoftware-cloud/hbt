import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../shared/services/api_client.dart';

/// Manages device registration and sync state for offline operation.
///
/// Each device gets a unique installation ID on first launch and
/// registers with the backend to participate in sync.
class DeviceRegistry extends ChangeNotifier {
  DeviceRegistry({required ApiClient api}) : _api = api;

  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  static const _installationIdKey = 'hbt_installation_id';
  static const _deviceRegisteredKey = 'hbt_device_registered';
  static const _lastSyncCursorKey = 'hbt_last_sync_cursor';

  String? _installationId;
  bool _registered = false;
  bool _registering = false;
  String? _lastSyncCursor;
  String? _error;

  /// Unique installation ID (persists across app restarts).
  String? get installationId => _installationId;

  /// Whether the device is registered with the backend.
  bool get registered => _registered;

  /// Whether a registration is in progress.
  bool get registering => _registering;

  /// Last known sync cursor (sequence number).
  String? get lastSyncCursor => _lastSyncCursor;

  String? get error => _error;

  /// Initialize from stored values. Call once on app startup.
  Future<void> initialize() async {
    _installationId = await _storage.read(key: _installationIdKey);
    if (_installationId == null) {
      _installationId = _uuid.v4();
      await _storage.write(
        key: _installationIdKey,
        value: _installationId!,
      );
    }
    _registered =
        (await _storage.read(key: _deviceRegisteredKey)) == 'true';
    _lastSyncCursor = await _storage.read(key: _lastSyncCursorKey);
    notifyListeners();
  }

  /// Register this device with the backend.
  Future<bool> register({
    required String platform,
    required String appVersion,
    String? deviceName,
  }) async {
    if (_installationId == null) return false;

    _registering = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post('/me/devices/', {
        'installation_id': _installationId,
        'platform': platform,
        'app_id': 'com.hbt.business',
        'app_version': appVersion,
        if (deviceName != null && deviceName.isNotEmpty)
          'device_name': deviceName,
      });

      await _storage.write(key: _deviceRegisteredKey, value: 'true');
      _registered = true;
      _registering = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _registering = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Device registration failed: $e';
      _registering = false;
      notifyListeners();
      return false;
    }
  }

  /// Update the last sync cursor.
  Future<void> updateSyncCursor(String cursor) async {
    _lastSyncCursor = cursor;
    await _storage.write(key: _lastSyncCursorKey, value: cursor);
    notifyListeners();
  }

  /// Clear all stored state (on sign-out or device revoke).
  Future<void> clear() async {
    await _storage.delete(key: _deviceRegisteredKey);
    await _storage.delete(key: _lastSyncCursorKey);
    _registered = false;
    _lastSyncCursor = null;
    _error = null;
    notifyListeners();
  }
}
