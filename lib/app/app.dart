import 'package:flutter/material.dart';

import 'theme/retro_theme.dart';
import '../data/repositories/map_repository.dart';
import '../data/repositories/sqlite_map_repository.dart';
import '../features/map/retro_walk_map_page.dart';

class RetroWalkMapApp extends StatelessWidget {
  RetroWalkMapApp({
    super.key,
    MapRepository? repository,
  }) : repository = repository ?? SqliteMapRepository();

  final MapRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'レトログ',
      debugShowCheckedModeBanner: false,
      theme: buildRetroTheme(),
      home: RetroWalkMapPage(repository: repository),
    );
  }
}
