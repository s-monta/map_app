import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/geo_utils.dart';
import '../../models/ruin_spot.dart';

class SeedRuinsLoader {
  static const _assetPath = 'assets/data/ruins.json';
  static const _satelliteOffsets = <(double east, double north, String suffix)>[
    (120, 35, '北東碑'),
    (-110, 50, '北西碑'),
    (95, -70, '南東碑'),
    (-85, -95, '南西碑'),
  ];

  Future<List<RuinSpot>> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    final coreRuins = decoded
        .map<RuinSpot>(
          (item) => RuinSpot.fromSeedJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);

    final satelliteRuins = coreRuins
        .expand<RuinSpot>((ruin) {
          return List<RuinSpot>.generate(_satelliteOffsets.length, (i) {
            final (east, north, suffix) = _satelliteOffsets[i];
            return RuinSpot(
              id: '${ruin.id}_satellite_$i',
              name: '${ruin.name}・$suffix',
              position: offsetFromMeters(
                ruin.position,
                east: east,
                north: north,
              ),
              inscription: ruin.inscription,
              obscuredStart: ruin.obscuredStart,
              obscuredEnd: ruin.obscuredEnd,
              isArtificial: ruin.isArtificial,
            );
          });
        })
        .toList(growable: false);

    return <RuinSpot>[
      ...coreRuins,
      ...satelliteRuins,
    ];
  }
}
