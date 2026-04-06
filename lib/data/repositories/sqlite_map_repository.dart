import 'package:latlong2/latlong.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../models/favorite_pin.dart';
import '../../models/memo_pin.dart';
import '../../models/ruin_spot.dart';
import '../database/database_factory.dart';
import '../seed/seed_ruins_loader.dart';
import 'map_repository.dart';

class SqliteMapRepository implements MapRepository {
  SqliteMapRepository({
    DatabaseFactory? databaseFactory,
    SeedRuinsLoader? seedRuinsLoader,
  })  : _databaseFactory = databaseFactory ?? createDatabaseFactory(),
        _seedRuinsLoader = seedRuinsLoader ?? SeedRuinsLoader();

  final DatabaseFactory _databaseFactory;
  final SeedRuinsLoader _seedRuinsLoader;

  CommonDatabase? _database;

  Future<CommonDatabase> get _db async {
    await initialize();
    return _database!;
  }

  @override
  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    final database = await _databaseFactory.open();
    _createTables(database);
    await _migrateRuinsTable(database);
    await _seedRuinsIfNeeded(database);
    _database = database;
  }

  @override
  Future<List<MemoPin>> loadMemos() async {
    final database = await _db;
    final rows = database.select(
      '''
      SELECT id, lat, lng, text, created_at
      FROM memos
      ORDER BY created_at DESC
      ''',
    );
    return rows
        .map<MemoPin>(
          (Row row) => MemoPin(
            id: row['id'] as String,
            position: LatLng(
              (row['lat'] as num).toDouble(),
              (row['lng'] as num).toDouble(),
            ),
            text: row['text'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<List<FavoritePin>> loadFavorites() async {
    final database = await _db;
    final rows = database.select(
      '''
      SELECT id, lat, lng, created_at
      FROM favorites
      ORDER BY created_at DESC
      ''',
    );
    return rows
        .map<FavoritePin>(
          (Row row) => _favoritePinFromRow(row),
        )
        .toList();
  }

  @override
  Future<List<RuinSpot>> loadRuins() async {
    final database = await _db;
    final rows = database.select(
      '''
      SELECT
        id,
        name,
        lat,
        lng,
        inscription,
        obscured_start,
        obscured_end,
        is_artificial
      FROM ruins
      ORDER BY is_artificial ASC, name ASC
      ''',
    );
    return rows
        .map<RuinSpot>(
          (Row row) => RuinSpot(
            id: row['id'] as String,
            name: row['name'] as String,
            position: LatLng(
              (row['lat'] as num).toDouble(),
              (row['lng'] as num).toDouble(),
            ),
            inscription: row['inscription'] as String,
            obscuredStart: row['obscured_start'] as int?,
            obscuredEnd: row['obscured_end'] as int?,
            isArtificial: (row['is_artificial'] as int) == 1,
          ),
        )
        .toList();
  }

  @override
  Future<MemoPin> createMemo({
    required double lat,
    required double lng,
    required String text,
    required DateTime createdAt,
  }) async {
    final database = await _db;
    final memo = MemoPin(
      id: 'memo_${createdAt.microsecondsSinceEpoch}',
      position: LatLng(lat, lng),
      text: text,
      createdAt: createdAt,
    );
    database.execute(
      '''
      INSERT INTO memos (id, lat, lng, text, created_at)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        memo.id,
        memo.position.latitude,
        memo.position.longitude,
        memo.text,
        memo.createdAt.toIso8601String(),
      ],
    );
    return memo;
  }

  @override
  Future<FavoritePin> createFavorite({
    required double lat,
    required double lng,
    required DateTime createdAt,
  }) async {
    final database = await _db;
    final favorite = FavoritePin(
      id: 'favorite_${createdAt.microsecondsSinceEpoch}',
      position: LatLng(lat, lng),
      createdAt: createdAt,
    );
    database.execute(
      '''
      INSERT INTO favorites (id, lat, lng, created_at)
      VALUES (?, ?, ?, ?)
      ''',
      [
        favorite.id,
        favorite.position.latitude,
        favorite.position.longitude,
        favorite.createdAt.toIso8601String(),
      ],
    );
    return favorite;
  }

  @override
  Future<void> deleteMemo(String id) async {
    final database = await _db;
    database.execute('DELETE FROM memos WHERE id = ?', [id]);
  }

  @override
  Future<RuinSpot> createArtificialRuin({
    required double lat,
    required double lng,
    required String inscription,
    required int obscuredStart,
    required int obscuredEnd,
  }) async {
    final database = await _db;
    final ruin = RuinSpot(
      id: 'user_ruin_${DateTime.now().microsecondsSinceEpoch}',
      name: '人工遺跡',
      position: LatLng(lat, lng),
      inscription: inscription,
      obscuredStart: obscuredStart,
      obscuredEnd: obscuredEnd,
      isArtificial: true,
    );
    database.execute(
      '''
      INSERT INTO ruins (
        id,
        name,
        lat,
        lng,
        inscription,
        obscured_start,
        obscured_end,
        is_artificial
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        ruin.id,
        ruin.name,
        ruin.position.latitude,
        ruin.position.longitude,
        ruin.inscription,
        ruin.obscuredStart,
        ruin.obscuredEnd,
        ruin.isArtificial ? 1 : 0,
      ],
    );
    return ruin;
  }

  @override
  Future<RuinSpot> updateArtificialRuin({
    required String id,
    required double lat,
    required double lng,
    required String inscription,
    required int obscuredStart,
    required int obscuredEnd,
  }) async {
    final database = await _db;
    final rows = database.select(
      '''
      SELECT id, name, lat, lng, inscription, obscured_start, obscured_end, is_artificial
      FROM ruins
      WHERE id = ?
      LIMIT 1
      ''',
      [id],
    );

    if (rows.isEmpty) {
      throw StateError('Artificial ruin not found: $id');
    }

    final existingRow = rows.first;
    final updated = RuinSpot(
      id: existingRow['id'] as String,
      name: existingRow['name'] as String,
      position: LatLng(lat, lng),
      inscription: inscription,
      obscuredStart: obscuredStart,
      obscuredEnd: obscuredEnd,
      isArtificial: (existingRow['is_artificial'] as int) == 1,
    );

    database.execute(
      '''
      UPDATE ruins
      SET lat = ?,
          lng = ?,
          inscription = ?,
          obscured_start = ?,
          obscured_end = ?
      WHERE id = ?
      ''',
      [
        updated.position.latitude,
        updated.position.longitude,
        updated.inscription,
        updated.obscuredStart,
        updated.obscuredEnd,
        updated.id,
      ],
    );

    return updated;
  }

  @override
  Future<void> deleteRuin(String id) async {
    final database = await _db;
    database.execute('DELETE FROM ruins WHERE id = ?', [id]);
  }

  void _createTables(CommonDatabase database) {
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS memos (
        id TEXT PRIMARY KEY,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
      ''',
    );
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS favorites (
        id TEXT PRIMARY KEY,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        created_at TEXT NOT NULL
      )
      ''',
    );
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS ruins (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        inscription TEXT NOT NULL,
        obscured_start INTEGER,
        obscured_end INTEGER,
        is_artificial INTEGER NOT NULL DEFAULT 0
      )
      ''',
    );
  }

  FavoritePin _favoritePinFromRow(Row row) {
    return FavoritePin(
      id: row['id'] as String,
      position: LatLng(
        (row['lat'] as num).toDouble(),
        (row['lng'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<void> _migrateRuinsTable(CommonDatabase database) async {
    final columns = database.select('PRAGMA table_info(ruins)');
    if (columns.isEmpty) {
      return;
    }

    final columnNames = columns.map((row) => row['name'] as String).toSet();
    final requiredColumns = <String>{
      'id',
      'name',
      'lat',
      'lng',
      'inscription',
      'obscured_start',
      'obscured_end',
      'is_artificial',
    };

    if (requiredColumns.difference(columnNames).isNotEmpty) {
      database.execute('ALTER TABLE ruins RENAME TO ruins_old');
      _createTables(database);
      database.execute(
        '''
        INSERT INTO ruins (
          id,
          name,
          lat,
          lng,
          inscription,
          obscured_start,
          obscured_end,
          is_artificial
        )
        SELECT
          id,
          name,
          lat,
          lng,
          COALESCE(inscription, ''),
          obscured_start,
          obscured_end,
          COALESCE(is_artificial, 0)
        FROM ruins_old
        ''',
      );
      database.execute('DROP TABLE ruins_old');
    }
  }

  Future<void> _seedRuinsIfNeeded(CommonDatabase database) async {
    final existing = database.select(
      'SELECT COUNT(*) AS count FROM ruins WHERE is_artificial = 0',
    );
    final count = (existing.first['count'] as num).toInt();
    if (count > 0) {
      return;
    }

    final ruins = await _seedRuinsLoader.load();
    database.execute('BEGIN');
    try {
      for (final ruin in ruins) {
        database.execute(
          '''
          INSERT INTO ruins (
            id,
            name,
            lat,
            lng,
            inscription,
            obscured_start,
            obscured_end,
            is_artificial
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            ruin.id,
            ruin.name,
            ruin.position.latitude,
            ruin.position.longitude,
            ruin.inscription,
            ruin.obscuredStart,
            ruin.obscuredEnd,
            ruin.isArtificial ? 1 : 0,
          ],
        );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }
}
