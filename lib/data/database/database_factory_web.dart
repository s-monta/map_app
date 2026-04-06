import 'package:sqlite3/wasm.dart';

import 'database_factory.dart';

class WebDatabaseFactory implements DatabaseFactory {
  static WasmSqlite3? _sqlite3;

  @override
  Future<CommonDatabase> open() async {
    final sqlite = _sqlite3 ??= await _loadSqlite();
    final database = sqlite.open('/retro_walk.sqlite');
    database.execute('PRAGMA foreign_keys = ON;');
    return database;
  }

  Future<WasmSqlite3> _loadSqlite() async {
    final sqlite = await WasmSqlite3.loadFromUrl(
      Uri.parse('sqlite3.wasm'),
    );
    final fileSystem = await IndexedDbFileSystem.open(
      dbName: 'retro_walk_file_system',
    );
    sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
    return sqlite;
  }
}

DatabaseFactory createPlatformDatabaseFactory() => WebDatabaseFactory();
