import 'package:sqlite3/common.dart';

import 'database_factory_native.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';

abstract class DatabaseFactory {
  Future<CommonDatabase> open();
}

DatabaseFactory createDatabaseFactory() => createPlatformDatabaseFactory();
