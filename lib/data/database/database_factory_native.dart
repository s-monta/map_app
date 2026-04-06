import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_factory.dart';

class NativeDatabaseFactory implements DatabaseFactory {
  @override
  Future<CommonDatabase> open() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final databasePath = path.join(supportDirectory.path, 'retro_walk.sqlite');
    final database = sqlite3.open(databasePath);
    database.execute('PRAGMA foreign_keys = ON;');
    return database;
  }
}

DatabaseFactory createPlatformDatabaseFactory() => NativeDatabaseFactory();
