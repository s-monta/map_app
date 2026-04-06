import 'package:latlong2/latlong.dart';

class MemoPin {
  const MemoPin({
    required this.id,
    required this.position,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final LatLng position;
  final String text;
  final DateTime createdAt;
}
