import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart' as sq;

/// Encrypted local database for offline data storage.
///
/// Uses sqflite_sqlcipher with a master key stored in secure storage.
/// Tables are created on first open and migrations applied sequentially.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;

  sq.Database? _db;
  bool _initialized = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _keyStorageKey = 'hbt_db_key';
  static const _schemaVersionKey = 'hbt_db_schema_version';
  static const _currentSchemaVersion = 3;

  static const _dbName = 'hbt_offline.db';

  /// Whether the database has been initialized.
  bool get isInitialized => _initialized;

  /// Whether the database is open and ready.
  bool get isOpen => _db != null;

  /// Initialize the database. Must be called once before any other method.
  Future<void> initialize() async {
    if (_initialized) return;

    // Get or create the encryption key
    final key = await _getOrCreateKey();

    // Get database path
    final dbPath = p.join(await _getDbDirectory(), _dbName);

    // Open encrypted database
    _db = await sq.openDatabase(
      dbPath,
      password: key,
      version: _currentSchemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA foreign_keys=ON');
      },
    );

    _initialized = true;
  }

  Future<String> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Generate a 256-bit hex key
    final bytes = List<int>.generate(32, (_) => DateTime.now().microsecondsSinceEpoch % 256);
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(key: _keyStorageKey, value: key);
    return key;
  }

  Future<String> _getDbDirectory() async {
    // Use a platform-appropriate directory
    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, sqflite uses getDatabasesPath()
      return sq.getDatabasesPath();
    }
    // Fallback for other platforms
    return Directory.current.path;
  }

  Future<void> _onCreate(sq.Database db, int version) async {
    // Create all tables
    await _createTables(db);
    await _secureStorage.write(
      key: _schemaVersionKey,
      value: version.toString(),
    );
  }

  Future<void> _onUpgrade(
    sq.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migration steps go here
    if (oldVersion < 1) {
      await _createTables(db);
    }
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_operations (
          client_operation_id TEXT PRIMARY KEY,
          operation_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          error_code TEXT,
          response_payload TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_ops_status ON sync_operations(status)',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE bookings ADD COLUMN authorization_reference TEXT',
      );
      await db.execute(
        'ALTER TABLE passengers ADD COLUMN full_name TEXT NOT NULL DEFAULT \'\'',
      );
    }
    await _secureStorage.write(
      key: _schemaVersionKey,
      value: newVersion.toString(),
    );
  }

  Future<void> _createTables(sq.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        trip_number TEXT NOT NULL,
        route_id TEXT,
        route_name TEXT,
        service_date TEXT,
        planned_departure_at TEXT,
        planned_arrival_at TEXT,
        status TEXT NOT NULL DEFAULT 'planned',
        vehicle_id TEXT,
        driver_id TEXT,
        conductor_id TEXT,
        operational_notes TEXT,
        data TEXT NOT NULL,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS routes (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        display_name TEXT,
        region TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        data TEXT NOT NULL,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        authorization_reference TEXT,
        trip_id TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        total_amount TEXT,
        currency TEXT DEFAULT 'MMK',
        data TEXT NOT NULL,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tickets (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        ticket_number TEXT NOT NULL,
        booking_id TEXT,
        passenger_name TEXT,
        seat_identifier TEXT,
        status TEXT NOT NULL DEFAULT 'issued',
        data TEXT NOT NULL,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS passengers (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        data TEXT NOT NULL,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fares (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        route_id TEXT,
        amount TEXT,
        currency TEXT DEFAULT 'MMK',
        data TEXT NOT NULL,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_operations (
        client_operation_id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        error_code TEXT,
        response_payload TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Indexes for common queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trips_org ON trips(organization_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_routes_org ON routes(organization_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bookings_org ON bookings(organization_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tickets_org ON tickets(organization_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_ops_status ON sync_operations(status)',
    );
  }

  // ── Generic CRUD helpers ─────────────────────────────────────────

  /// Insert or replace a record.
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    _ensureOpen();
    final ts = DateTime.now().toUtc().toIso8601String();
    row.putIfAbsent('created_at', () => ts);
    row['updated_at'] = ts;
    await _db!.insert(
      table,
      row,
      conflictAlgorithm: sq.ConflictAlgorithm.replace,
    );
  }

  /// Insert or replace multiple records in a transaction.
  Future<void> upsertAll(String table, List<Map<String, dynamic>> rows) async {
    _ensureOpen();
    final ts = DateTime.now().toUtc().toIso8601String();
    await _db!.transaction((txn) async {
      for (final row in rows) {
        row.putIfAbsent('created_at', () => ts);
        row['updated_at'] = ts;
        await txn.insert(
          table,
          row,
          conflictAlgorithm: sq.ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Query records.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    _ensureOpen();
    return _db!.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Get a single record by primary key.
  Future<Map<String, dynamic>?> get(String table, String id) async {
    _ensureOpen();
    final results = await _db!.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : results.first;
  }

  /// Delete a record by primary key.
  Future<int> delete(String table, String id) async {
    _ensureOpen();
    return _db!.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Count records.
  Future<int> count(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _ensureOpen();
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return sq.Sqflite.firstIntValue(result) ?? 0;
  }

  /// Execute raw SQL (for migrations or cleanup).
  Future<void> execute(String sql, [List<Object?>? args]) async {
    _ensureOpen();
    await _db!.execute(sql, args);
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _initialized = false;
    }
  }

  void _ensureOpen() {
    if (_db == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
  }

  /// Clear all data (for sign-out or full resync).
  Future<void> clearAll() async {
    _ensureOpen();
    await _db!.transaction((txn) async {
      for (final table in [
        'trips',
        'routes',
        'bookings',
        'tickets',
        'passengers',
        'fares',
      ]) {
        await txn.delete(table);
      }
      await txn.delete('sync_operations');
    });
  }

  /// Delete all completed sync operations (housekeeping).
  Future<void> clearCompletedOperations() async {
    _ensureOpen();
    await _db!.delete(
      'sync_operations',
      where: 'status IN (?, ?, ?)',
      whereArgs: ['completed', 'rejected', 'conflict'],
    );
  }

  /// Mark stale pending operations as failed (on connectivity loss).
  Future<void> failStaleOperations() async {
    _ensureOpen();
    final ts = DateTime.now().toUtc().toIso8601String();
    await _db!.execute(
      "UPDATE sync_operations SET status = 'failed', error_code = 'sync_failed', updated_at = ? WHERE status IN ('pending', 'uploading')",
      [ts],
    );
  }
}
