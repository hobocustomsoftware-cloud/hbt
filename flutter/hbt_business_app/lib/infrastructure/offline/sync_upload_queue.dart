import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../../shared/services/api_client.dart';
import 'device_registry.dart';

/// Status of a queued sync operation.
enum UploadStatus {
  /// Waiting to be sent.
  pending,

  /// Currently being sent to the server.
  uploading,

  /// Successfully applied by the server.
  completed,

  /// Server rejected the operation (permanent failure).
  rejected,

  /// Server returned a conflict that needs manual resolution.
  conflict,

  /// Client-side failure (network error, etc.).
  failed,
}

/// A single operation queued for upload to the server.
///
/// Backed by the `sync_operations` table in the local encrypted database.
/// Each operation has a unique [clientOperationId] (UUID v4) for
/// idempotency — the backend will reject duplicate submissions.
class UploadOperation {
  final String clientOperationId;
  final String operationType;
  final Map<String, dynamic> payload;
  final UploadStatus status;
  final String? errorCode;
  final Map<String, dynamic>? responsePayload;
  final String createdAt;
  final String updatedAt;

  UploadOperation({
    required this.clientOperationId,
    required this.operationType,
    required this.payload,
    this.status = UploadStatus.pending,
    this.errorCode,
    this.responsePayload,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  /// Whether this operation has reached a terminal state.
  bool get isTerminal =>
      status == UploadStatus.completed ||
      status == UploadStatus.rejected ||
      status == UploadStatus.conflict;

  /// Whether this operation can be retried.
  bool get isRetryable =>
      status == UploadStatus.failed || status == UploadStatus.pending;

  /// Create from a database row.
  factory UploadOperation.fromRow(Map<String, dynamic> row) =>
      UploadOperation(
        clientOperationId: row['client_operation_id'] as String,
        operationType: row['operation_type'] as String,
        payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        status: UploadStatus.values.firstWhere(
          (s) => s.name == row['status'],
          orElse: () => UploadStatus.pending,
        ),
        errorCode: row['error_code'] as String?,
        responsePayload: row['response_payload'] != null &&
                (row['response_payload'] as String).isNotEmpty
            ? jsonDecode(row['response_payload'] as String)
                as Map<String, dynamic>
            : null,
        createdAt: row['created_at'] as String,
        updatedAt: row['updated_at'] as String,
      );

  /// Serialize to a database row.
  Map<String, dynamic> toRow() => {
        'client_operation_id': clientOperationId,
        'operation_type': operationType,
        'payload': jsonEncode(payload),
        'status': status.name,
        'error_code': errorCode ?? '',
        'response_payload': responsePayload != null
            ? jsonEncode(responsePayload)
            : '',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Create a copy with updated fields.
  UploadOperation copyWith({
    UploadStatus? status,
    String? errorCode,
    Map<String, dynamic>? responsePayload,
  }) =>
      UploadOperation(
        clientOperationId: clientOperationId,
        operationType: operationType,
        payload: payload,
        status: status ?? this.status,
        errorCode: errorCode ?? this.errorCode,
        responsePayload: responsePayload ?? this.responsePayload,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
}

/// Manages the queue of upload operations for offline-to-online sync.
///
/// Operations created while offline are persisted to the local encrypted
/// database and sent to the server in batches when connectivity returns.
///
/// ## Supported operation types
/// (matches `OFFLINE_OPERATION_HANDLERS` in `backend/apps/offline/services.py`)
///
/// | Operation | Payload | Description |
/// |-----------|---------|-------------|
/// | `trip.transition` | `{trip_id, event_type, ...}` | Advance a trip to next status |
/// | `ticket.validate` | `{trip_id, validation_code, ...}` | Validate a passenger ticket |
/// | `cargo.transition` | `{shipment_id, to_status, ...}` | Advance cargo status |
/// | `cargo.accept` | `{sender, receiver, ...}` | Accept a new cargo shipment |
/// | `payment.record_cash` | `{payment_number, amount, ...}` | Record cash payment |
/// | `booking.walk_up` | `{trip, pickup_stop, ...}` | Create a walk-up booking |
class SyncUploadQueue extends ChangeNotifier {
  SyncUploadQueue({
    required ApiClient api,
    required AppDatabase database,
    required DeviceRegistry device,
  })  : _api = api,
        _database = database,
        _device = device;

  final ApiClient _api;
  final AppDatabase _database;
  final DeviceRegistry _device;
  final Uuid _uuid = const Uuid();

  bool _uploading = false;
  int _lastBatchSize = 0;

  /// Whether an upload is in progress.
  bool get uploading => _uploading;

  /// The size of the last batch sent.
  int get lastBatchSize => _lastBatchSize;

  // ── Enqueue ───────────────────────────────────────────────────────

  /// Enqueue an operation for upload.
  ///
  /// Returns the unique client operation ID.
  Future<String> enqueue(
    String operationType,
    Map<String, dynamic> payload,
  ) async {
    final id = _uuid.v4();
    final op = UploadOperation(
      clientOperationId: id,
      operationType: operationType,
      payload: payload,
    );
    await _database.upsert('sync_operations', op.toRow());
    notifyListeners();
    return id;
  }

  // ── Query ─────────────────────────────────────────────────────────

  /// Count operations by status.
  Future<int> countByStatus(UploadStatus status) =>
      _database.count('sync_operations', where: 'status = ?', whereArgs: [status.name]);

  /// Total pending (including retryable failed) operations.
  Future<int> get pendingCount => _database.count(
        'sync_operations',
        where: 'status IN (?, ?)',
        whereArgs: ['pending', 'failed'],
      );

  /// Get all pending/retryable operations, oldest first.
  Future<List<UploadOperation>> _pendingOperations() async {
    final rows = await _database.query(
      'sync_operations',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => UploadOperation.fromRow(r)).toList();
  }

  /// Get operations by status.
  Future<List<UploadOperation>> getByStatus(UploadStatus status) async {
    final rows = await _database.query(
      'sync_operations',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => UploadOperation.fromRow(r)).toList();
  }

  // ── Upload ────────────────────────────────────────────────────────

  /// Push all pending operations to the server in batches.
  ///
  /// Returns the number of batches processed.
  /// Returns -1 if prerequisites are not met (not registered, no org).
  Future<int> pushAll(String organizationId) async {
    if (_uploading) return 0;
    if (_device.installationId == null || !_device.registered) return -1;

    final pending = await _pendingOperations();
    if (pending.isEmpty) return 0;

    _uploading = true;
    notifyListeners();

    int batches = 0;
    const batchSize = 50; // well under server max of 100

    try {
      for (var i = 0; i < pending.length; i += batchSize) {
        final batch = pending.sublist(
          i,
          i + batchSize > pending.length ? pending.length : i + batchSize,
        );

        // Mark as uploading
        await _markBatchStatus(batch, UploadStatus.uploading);

        final succeeded = await _sendBatch(organizationId, batch);

        if (succeeded) {
          batches++;
        } else {
          // Network error — mark remaining as failed and stop
          for (var j = 0; j < batch.length; j++) {
            await _updateStatus(batch[j], UploadStatus.failed,
                errorCode: 'network_error');
          }
          // Mark rest as failed too
          final remaining = pending.sublist(i + batch.length);
          for (final op in remaining) {
            await _updateStatus(op, UploadStatus.failed,
                errorCode: 'network_error');
          }
          break;
        }
      }
    } finally {
      _uploading = false;
      _lastBatchSize = batches;
      notifyListeners();
    }

    return batches;
  }

  /// Send a single batch to the push endpoint and process results.
  Future<bool> _sendBatch(
    String organizationId,
    List<UploadOperation> batch,
  ) async {
    final deviceId = _device.installationId!;
    final path =
        '/organizations/$organizationId/devices/$deviceId/sync/push/';

    final requestBody = batch.map((op) => {
          'client_operation_id': op.clientOperationId,
          'operation_type': op.operationType,
          'payload': op.payload,
        }).toList();

    try {
      final response = await _api.postJson(path, requestBody);
      final operations = response['operations'] as List<dynamic>? ?? [];

      for (final item in operations) {
        final clientId = item['client_operation_id'] as String? ?? '';
        final status = item['status'] as String? ?? 'applied';
        final errorCode = item['error_code'] as String?;
        final responsePayload =
            item['response_payload'] as Map<String, dynamic>?;

        final pendingOp = batch.firstWhere(
          (op) => op.clientOperationId == clientId,
        );

        switch (status) {
          case 'applied':
            await _updateStatus(
              pendingOp,
              UploadStatus.completed,
              responsePayload: responsePayload,
            );
            break;
          case 'rejected':
            await _updateStatus(
              pendingOp,
              UploadStatus.rejected,
              errorCode: errorCode,
              responsePayload: responsePayload,
            );
            break;
          case 'conflict':
            await _updateStatus(
              pendingOp,
              UploadStatus.conflict,
              errorCode: errorCode,
              responsePayload: responsePayload,
            );
            break;
          case 'received':
          default:
            // Should not happen, but treat as pending
            await _updateStatus(pendingOp, UploadStatus.pending);
        }
      }

      return true;
    } on ApiException {
      return false; // Server error — caller will mark as failed
    } catch (_) {
      return false; // Network error
    }
  }

  // ── Status management ─────────────────────────────────────────────

  Future<void> _markBatchStatus(
    List<UploadOperation> batch,
    UploadStatus status,
  ) async {
    final ids = batch.map((op) => op.clientOperationId).toList();
    final ts = DateTime.now().toUtc().toIso8601String();
    for (final id in ids) {
      await _database.execute(
        "UPDATE sync_operations SET status = ?, updated_at = ? WHERE client_operation_id = ?",
        [status.name, ts, id],
      );
    }
  }

  Future<void> _updateStatus(
    UploadOperation op,
    UploadStatus status, {
    String? errorCode,
    Map<String, dynamic>? responsePayload,
  }) async {
    final ts = DateTime.now().toUtc().toIso8601String();
    await _database.execute(
      "UPDATE sync_operations SET status = ?, error_code = ?, response_payload = ?, updated_at = ? WHERE client_operation_id = ?",
      [
        status.name,
        errorCode ?? '',
        responsePayload != null ? jsonEncode(responsePayload) : '',
        ts,
        op.clientOperationId,
      ],
    );
  }

  // ── Retry & cleanup ───────────────────────────────────────────────

  /// Retry a specific failed operation.
  Future<void> retry(String clientOperationId) async {
    final ts = DateTime.now().toUtc().toIso8601String();
    await _database.execute(
      "UPDATE sync_operations SET status = 'pending', error_code = '', response_payload = '', updated_at = ? WHERE client_operation_id = ?",
      [ts, clientOperationId],
    );
    notifyListeners();
  }

  /// Retry all failed operations.
  Future<void> retryAll() async {
    final ts = DateTime.now().toUtc().toIso8601String();
    await _database.execute(
      "UPDATE sync_operations SET status = 'pending', error_code = '', response_payload = '', updated_at = ? WHERE status = 'failed'",
      [ts],
    );
    notifyListeners();
  }

  /// Remove completed/terminal operations older than [maxAge].
  Future<void> clean({Duration maxAge = const Duration(days: 7)}) async {
    final cutoff =
        DateTime.now().subtract(maxAge).toUtc().toIso8601String();
    await _database.execute(
      "DELETE FROM sync_operations WHERE status IN ('completed', 'rejected', 'conflict') AND created_at < ?",
      [cutoff],
    );
  }

  /// Conflict operations that need user attention.
  Future<List<UploadOperation>> get conflicts =>
      getByStatus(UploadStatus.conflict);

  /// Clear all operations (on sign-out).
  Future<void> clear() async {
    await _database.execute('DELETE FROM sync_operations');
    notifyListeners();
  }
}
