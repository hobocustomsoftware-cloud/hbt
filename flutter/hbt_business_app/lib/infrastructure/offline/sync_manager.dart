import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../shared/services/api_client.dart';
import 'device_registry.dart';
import 'sync_upload_queue.dart';

/// Manages sync push/pull operations with the backend.
///
/// Handles pulling changes from the server and pushing local changes
/// via [SyncUploadQueue]. Depends on [AppDatabase] for local storage
/// and [DeviceRegistry] for device identity.
class SyncManager extends ChangeNotifier {
  SyncManager({
    required ApiClient api,
    required AppDatabase database,
    required DeviceRegistry device,
  })  : _api = api,
        _database = database,
        _device = device,
        uploadQueue = SyncUploadQueue(
          api: api,
          database: database,
          device: device,
        );

  final ApiClient _api;
  final AppDatabase _database;
  final DeviceRegistry _device;

  /// The upload queue for pushing local changes to the server.
  final SyncUploadQueue uploadQueue;

  bool _syncing = false;
  String? _lastError;
  double? _progress; // 0.0 – 1.0

  bool get syncing => _syncing;
  String? get lastError => _lastError;
  double? get progress => _progress;

  /// Run a full sync cycle: push pending changes, then pull server changes.
  ///
  /// Returns `true` if both push and pull succeeded (or had nothing to do),
  /// `false` if either step failed.
  Future<bool> syncAll(String organizationId) async {
    if (_syncing) return false;
    if (_device.installationId == null) return false;

    _syncing = true;
    _lastError = null;
    _progress = 0.0;
    notifyListeners();

    try {
      // Step 1: Push local changes to server
      _lastError = null;
      notifyListeners();

      final batches = await uploadQueue.pushAll(organizationId);
      if (batches < 0) {
        _lastError = 'Device not registered with server.';
        _syncing = false;
        notifyListeners();
        return false;
      }

      _progress = 0.5;
      notifyListeners();

      // Step 2: Pull server changes to local database
      final pulled = await _pullInternal(organizationId);

      _progress = 1.0;
      _syncing = false;
      notifyListeners();

      return pulled;
    } on ApiException catch (e) {
      _lastError = e.message;
      _syncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Sync failed: $e';
      _syncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Pull the latest changes from the backend.
  Future<bool> pull(String organizationId) async {
    if (_device.installationId == null || _syncing) return false;

    _syncing = true;
    _lastError = null;
    _progress = 0.0;
    notifyListeners();

    try {
      final result = await _pullInternal(organizationId);
      _syncing = false;
      _progress = 1.0;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _lastError = e.message;
      _syncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Sync pull failed: $e';
      _syncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Internal pull implementation (shared by [pull] and [syncAll]).
  Future<bool> _pullInternal(String organizationId) async {
    final cursor = _device.lastSyncCursor;
    final path = cursor != null
        ? '/organizations/$organizationId/devices/${_device.installationId}/sync/pull/?after=$cursor'
        : '/organizations/$organizationId/devices/${_device.installationId}/sync/pull/';

    final response = await _api.get(path);

    // Apply changes to local database
    final changes = response['changes'] as List<dynamic>? ?? [];
    final newCursor = response['next_cursor'] as int?;

    for (var i = 0; i < changes.length; i++) {
      final change = changes[i] as Map<String, dynamic>;

      final resourceType = change['resource_type'] as String? ?? '';
      final operation = change['operation'] as String? ?? '';
      final payload = change['payload'] as Map<String, dynamic>? ?? {};
      final resourceId = change['resource_id']?.toString() ?? '';

      await _applyChange(resourceType, operation, resourceId, payload);

      _progress = 0.5 + ((i + 1) / changes.length) * 0.5;
      if (i % 5 == 0) notifyListeners();
    }

    if (newCursor != null) {
      await _device.updateSyncCursor(newCursor.toString());
    }

    return true;
  }

  /// Apply a single change to the local database based on resource type.
  Future<void> _applyChange(
    String resourceType,
    String operation,
    String resourceId,
    Map<String, dynamic> payload,
  ) async {
    // Determine table name from resource type
    final table = _resourceTable(resourceType);
    if (table == null) return;

    switch (operation) {
      case 'create':
      case 'update':
        final row = _buildRow(table, resourceId, payload);
        if (row != null) {
          await _database.upsert(table, row);
        }
        break;
      case 'delete':
        await _database.delete(table, resourceId);
        break;
    }
  }

  /// Map resource type to local table name.
  String? _resourceTable(String resourceType) => switch (resourceType) {
    'trip' || 'trips' => 'trips',
    'route' || 'routes' => 'routes',
    'booking' || 'bookings' => 'bookings',
    'ticket' || 'tickets' => 'tickets',
    'passenger' || 'passengers' => 'passengers',
    'fare' || 'fares' => 'fares',
    _ => null,
  };

  /// Build a database row from a sync payload.
  Map<String, dynamic>? _buildRow(
    String table,
    String id,
    Map<String, dynamic> payload,
  ) {
    final now = DateTime.now().toUtc().toIso8601String();
    final base = <String, dynamic>{
      'id': id,
      'data': payload.toString(),
      'synced_at': now,
      'updated_at': now,
    };

    // Extract common fields
    base['organization_id'] = payload['organization_id']?.toString();
    base['status'] = payload['status']?.toString() ?? '';

    // Table-specific field extraction
    switch (table) {
      case 'trips':
        base['trip_number'] = payload['trip_number']?.toString() ?? '';
        base['route_id'] = payload['route']?.toString();
        base['service_date'] = payload['service_date']?.toString();
        base['planned_departure_at'] =
            payload['planned_departure_at']?.toString();
        base['planned_arrival_at'] =
            payload['planned_arrival_at']?.toString();
        base['vehicle_id'] = payload['vehicle']?.toString();
        base['driver_id'] = payload['driver']?.toString();
        base['conductor_id'] = payload['conductor']?.toString();
        break;
      case 'routes':
        base['code'] = payload['code']?.toString() ?? '';
        base['name'] = payload['name']?.toString() ?? '';
        base['display_name'] = payload['display_name']?.toString();
        base['region'] = payload['region']?.toString();
        break;
      case 'bookings':
        base['authorization_reference'] =
            payload['authorization_reference']?.toString();
        base['trip_id'] = payload['trip']?.toString();
        base['total_amount'] = payload['total_amount']?.toString();
        break;
      case 'tickets':
        base['ticket_number'] =
            payload['ticket_number']?.toString() ?? '';
        base['booking_id'] = payload['booking']?.toString();
        base['passenger_name'] =
            payload['passenger_name']?.toString();
        base['seat_identifier'] =
            payload['seat_identifier']?.toString();
        break;
      case 'passengers':
        base['full_name'] =
            payload['full_name']?.toString() ?? '';
        base['phone_number'] =
            payload['phone_number']?.toString() ?? '';
        break;
    }

    return base;
  }

  /// Clear sync state on sign-out.
  Future<void> clear() async {
    await uploadQueue.clear();
    _lastError = null;
    _progress = null;
    notifyListeners();
  }
}
