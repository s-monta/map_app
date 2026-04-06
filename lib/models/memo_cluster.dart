import 'package:latlong2/latlong.dart';

import 'memo_pin.dart';

class MemoCluster {
  MemoCluster({
    required this.center,
    required this.memos,
  });

  final LatLng center;
  final List<MemoPin> memos;
}
