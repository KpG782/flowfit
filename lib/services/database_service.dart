import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tracked_data.dart';

/// Local database service for storing heart rate data
/// Implements best practices for data persistence
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flowfit.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Heart rate data table
    await db.execute('''
      CREATE TABLE heart_rate_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hr INTEGER NOT NULL,
        ibi_values TEXT,
        hrv REAL NOT NULL,
        spo2 INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create index on timestamp for faster queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON heart_rate_data(timestamp DESC)
    ''');

    // Create index on synced status
    await db.execute('''
      CREATE INDEX idx_synced ON heart_rate_data(synced)
    ''');
  }

  /// Insert heart rate data
  Future<int> insertHeartRateData(TrackedData data) async {
    final db = await database;
    final map = data.toDatabaseMap();
    map['synced'] = 0; // Mark as not synced
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;

    return await db.insert('heart_rate_data', map);
  }

  /// Insert multiple heart rate data (batch insert)
  Future<void> insertHeartRateDataBatch(List<TrackedData> dataList) async {
    final db = await database;
    final batch = db.batch();

    for (final data in dataList) {
      final map = data.toDatabaseMap();
      map['synced'] = 0;
      map['created_at'] = DateTime.now().millisecondsSinceEpoch;
      batch.insert('heart_rate_data', map);
    }

    await batch.commit(noResult: true);
  }

  /// Get recent heart rate data (last N records)
  Future<List<TrackedData>> getRecentHeartRateData({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'heart_rate_data',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => TrackedData.fromDatabaseMap(map)).toList();
  }

  /// Get heart rate data by date range
  Future<List<TrackedData>> getHeartRateDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'heart_rate_data',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => TrackedData.fromDatabaseMap(map)).toList();
  }

  /// Get unsynced heart rate data (for uploading to backend)
  Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    final db = await database;
    return await db.query(
      'heart_rate_data',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  /// Mark data as synced
  Future<void> markAsSynced(List<int> ids) async {
    final db = await database;
    final batch = db.batch();

    for (final id in ids) {
      batch.update(
        'heart_rate_data',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Delete old data (keep last N days)
  Future<int> deleteOldData({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return await db.delete(
      'heart_rate_data',
      where: 'timestamp < ? AND synced = ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch, 1],
    );
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    // Total records
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM heart_rate_data',
    );
    final total = totalResult.first['count'] as int;

    // Unsynced records
    final unsyncedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM heart_rate_data WHERE synced = 0',
    );
    final unsynced = unsyncedResult.first['count'] as int;

    // Date range
    final rangeResult = await db.rawQuery(
      'SELECT MIN(timestamp) as min, MAX(timestamp) as max FROM heart_rate_data',
    );
    final minTimestamp = rangeResult.first['min'] as int?;
    final maxTimestamp = rangeResult.first['max'] as int?;

    return {
      'total_records': total,
      'unsynced_records': unsynced,
      'oldest_record': minTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(minTimestamp)
          : null,
      'newest_record': maxTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(maxTimestamp)
          : null,
    };
  }

  /// Clear all data (use with caution)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('heart_rate_data');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

