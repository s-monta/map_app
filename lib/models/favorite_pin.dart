import 'package:latlong2/latlong.dart';

class FavoritePin {
  const FavoritePin({
    required this.id,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final LatLng position;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'lat': position.latitude,
      'lng': position.longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FavoritePin.fromJson(Map<String, dynamic> json) {
    return FavoritePin(
      id: json['id'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
