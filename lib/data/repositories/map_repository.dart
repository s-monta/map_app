import '../../models/favorite_pin.dart';
import '../../models/memo_pin.dart';
import '../../models/ruin_spot.dart';

/// UI が依存するメモ・遺跡・お気に入り永続化の抽象契約。
///
/// この抽象は SQLite 実装と完全に同じ保存・取得前提を持つこと。
/// 画面側が参照するのは [MapRepository] までに留め、
/// データの実体やカラム差分は [sqlite_map_repository.dart] 側へ閉じ込める。
///
/// 遺跡については [RuinSpot] の定義を正式な契約とする。
/// もし新しい項目を採用する場合は、モデル / 抽象 / SQLite 実装 / seed の
/// すべてを同時に更新し、片側だけが先行してずれる状態を作らないこと。
abstract class MapRepository {
  Future<void> initialize();
  Future<List<MemoPin>> loadMemos();
  Future<List<RuinSpot>> loadRuins();
  Future<List<FavoritePin>> loadFavorites();
  Future<MemoPin> createMemo({
    required double lat,
    required double lng,
    required String text,
    required DateTime createdAt,
  });
  Future<FavoritePin> createFavorite({
    required double lat,
    required double lng,
    required DateTime createdAt,
  });
  Future<void> deleteMemo(String id);

  /// 画面上で人工遺跡を新規作成する。
  ///
  /// [inscription] は遺跡の表示文言、[obscuredStart] / [obscuredEnd] は
  /// 文字の伏字範囲を表す。
  /// 戻り値は SQLite 実装と同じく保存後の [RuinSpot] とする。
  Future<RuinSpot> createArtificialRuin({
    required double lat,
    required double lng,
    required String inscription,
    required int obscuredStart,
    required int obscuredEnd,
  });

  /// 既存の人工遺跡を更新する。
  ///
  /// SQLite 実装と同一の契約を保つため、戻り値は更新後の [RuinSpot] を返す。
  /// [inscription] は遺跡の表示文言、[obscuredStart] / [obscuredEnd] は
  /// 文字の伏字範囲を表す。
  ///
  /// 実装は、対象が存在しない・保存に失敗した等の異常時には例外を投げる。
  Future<RuinSpot> updateArtificialRuin({
    required String id,
    required double lat,
    required double lng,
    required String inscription,
    required int obscuredStart,
    required int obscuredEnd,
  });

  Future<void> deleteRuin(String id);
}
