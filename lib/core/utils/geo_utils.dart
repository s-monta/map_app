import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

LatLng offsetFromMeters(
  LatLng base, {
  required double east,
  required double north,
}) {
  const metersPerLatDegree = 111320.0;
  final metersPerLngDegree =
      metersPerLatDegree * math.cos(base.latitude * math.pi / 180);
  final lat = base.latitude + north / metersPerLatDegree;
  final lng = base.longitude + east / metersPerLngDegree;
  return LatLng(lat, lng);
}
