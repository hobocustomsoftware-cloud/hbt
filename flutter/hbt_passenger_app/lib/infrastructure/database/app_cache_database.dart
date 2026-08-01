import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local cache for passenger trip data (offline reads).
///
/// Stores the last successful API payloads keyed by request path so the app
/// can serve stale-but-usable data when offline. Cache only — no PII, no
/// booking state (writes stay online-only per M0 seat-lock design).
///
/// Schema versioning: bump [schemaVersion] and add a migration in
/// [_onCreate]/[_onUpgrade]. Cache is safe to drop-and-recreate.
class AppCacheDatabase {
  AppCacheDatabase._();

  static final AppCacheDatabase instance = AppCacheDatabase._();

  static const int schemaVersion = 1;

  Database? _db;

  /// Path of the open database (exposed for tests).
  String? get path => _db?.path;

  Future<Database> _open() async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    final dir = await getDatabasesPath();
    final opened = await openDatabase(
      p.join(dir, 'hbt_passenger_cache.db'),
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _db = opened;
    return opened;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE response_cache (
        cache_key TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        fetched_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_response_cache_fetched_at
      ON response_cache(fetched_at)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations yet (schemaVersion 1). Future versions add ALTER/CREATE
    // here, mirroring backend migration discipline.
  }

  /// Persist a successful API payload under [cacheKey].
  Future<void> put(String cacheKey, Object payload) async {
    final db = await _open();
    await db.insert(
      'response_cache',
      {
        'cache_key': cacheKey,
        'payload': jsonEncode(payload),
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Read a cached payload. Returns `null` when absent.
  Future<Object?> get(String cacheKey) async {
    final db = await _open();
    final rows = await db.query(
      'response_cache',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String);
  }

  /// When the entry was cached, or `null` if absent.
  Future<DateTime?> fetchedAt(String cacheKey) async {
    final db = await _open();
    final rows = await db.query(
      'response_cache',
      columns: ['fetched_at'],
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['fetched_at'] as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Drop everything (used by tests; cache is disposable by design).
  Future<void> clear() async {
    final db = await _open();
    await db.delete('response_cache');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
      _db = null;
    }
  }
}
