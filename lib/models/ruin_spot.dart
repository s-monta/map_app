import 'package:latlong2/latlong.dart';

/// 遺跡スポットのモデル。
///
/// このモデルは、画面表示と永続化の両方で使う最小単位のデータを表す。
///
/// 永続化対象の項目:
/// - [id]
/// - [name]
/// - [position]
/// - [inscription]
/// - [obscuredStart]
/// - [obscuredEnd]
/// - [isArtificial]
///
/// 既存データ互換のため、[obscuredStart] / [obscuredEnd] / [isArtificial] は
/// 省略時に null / false として扱う。
class RuinSpot {
  const RuinSpot({
    required this.id,
    required this.name,
    required this.position,
    required this.inscription,
    this.obscuredStart,
    this.obscuredEnd,
    this.isArtificial = false,
  });

  final String id;
  final String name;
  final LatLng position;

  /// 遺跡に表示する碑文/文言。
  ///
  /// このプロジェクトではこれを単一の真実の定義源として扱う。
  final String inscription;

  /// 文字化け対象の開始位置。
  /// コードポイント単位の 0-based index。
  final int? obscuredStart;

  /// 文字化け対象の終了位置。
  /// コードポイント単位の end-exclusive index。
  final int? obscuredEnd;

  /// 人工遺跡かどうか。
  ///
  /// 旧データには存在しないため、未指定時は false を採用する。
  final bool isArtificial;

  /// 旧JSON/seedデータ互換のため、snake_case / 旧フィールド名を吸収して読み込む。
  factory RuinSpot.fromSeedJson(Map<String, dynamic> json) {
    return RuinSpot(
      id: json['id'] as String,
      name: json['name'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      inscription: (json['inscription'] ??
          json['obscuredInscription'] ??
          json['originalInscription']) as String,
      obscuredStart: _readNullableInt(
        json['obscuredStart'] ?? json['obscuredStartIndex'],
      ),
      obscuredEnd: _readNullableInt(
        json['obscuredEnd'] ?? json['obscuredEndIndex'],
      ),
      isArtificial: (json['isArtificial'] as bool?) ?? false,
    );
  }

  /// DB/JSON へ保存する際の標準形。
  ///
  /// SQLite 側の列マッピングはこの形式に合わせる。
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'lat': position.latitude,
      'lng': position.longitude,
      'inscription': inscription,
      'obscuredStart': obscuredStart,
      'obscuredEnd': obscuredEnd,
      'isArtificial': isArtificial,
    };
  }

  /// SQLite の row map など、DB列名を含む入力を受ける。
  ///
  /// snake_case / camelCase の両方を許容し、既存DBとの互換性を保つ。
  factory RuinSpot.fromJson(Map<String, dynamic> json) {
    return RuinSpot(
      id: json['id'] as String,
      name: json['name'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      inscription: (json['inscription'] ??
          json['obscuredInscription'] ??
          json['originalInscription']) as String,
      obscuredStart: _readNullableInt(
        json['obscuredStart'] ?? json['obscured_start'] ?? json['obscuredStartIndex'],
      ),
      obscuredEnd: _readNullableInt(
        json['obscuredEnd'] ?? json['obscured_end'] ?? json['obscuredEndIndex'],
      ),
      isArtificial: (json['isArtificial'] as bool?) ??
          _readNullableBool(json['is_artificial']) ??
          false,
    );
  }

  RuinSpot copyWith({
    String? id,
    String? name,
    LatLng? position,
    String? inscription,
    int? obscuredStart,
    int? obscuredEnd,
    bool? isArtificial,
  }) {
    return RuinSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      inscription: inscription ?? this.inscription,
      obscuredStart: obscuredStart ?? this.obscuredStart,
      obscuredEnd: obscuredEnd ?? this.obscuredEnd,
      isArtificial: isArtificial ?? this.isArtificial,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RuinSpot &&
        other.id == id &&
        other.name == name &&
        other.position.latitude == position.latitude &&
        other.position.longitude == position.longitude &&
        other.inscription == inscription &&
        other.obscuredStart == obscuredStart &&
        other.obscuredEnd == obscuredEnd &&
        other.isArtificial == isArtificial;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      position.latitude,
      position.longitude,
      inscription,
      obscuredStart,
      obscuredEnd,
      isArtificial,
    );
  }

  static int? _readNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _readNullableBool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }
}
