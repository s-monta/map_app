# Repository Map

このファイルは「まず何を読むべきか」だけを最短で判断するための地図。
詳細実装を全部読む前に、このページで対象ファイルを絞ること。

## 0. アプリ仕様要約（AI向け）

- 目的: レトロな地図アプリで、現在地を中心にメモと遺跡を記録・解読する単一画面アプリ。
- 画面構成: 地図 + 下部の開閉パネル。モバイルは全画面、web/desktop は端末フレーム風のプレビュー表示。
- 起動フロー: DB初期化 → メモ/遺跡読込 → 位置情報権限確認 → 現在地取得 → 追従監視。失敗時はステータス文言で案内する。
- 主要機能: 現在地メモの追加/削除/詳細、メモのクラスタ表示、人工遺跡の追加/削除/詳細、遺跡図鑑表示。
- 遺跡仕様: `assets/data/ruins.json` が seed の本体で、周辺4方向の衛星遺跡を自動生成する。未解読時は碑文の一部を文字化け表示し、現地到達で全文解読する。解読状態はセッション内のみで永続化しない。seed遺跡は削除不可・人工遺跡は削除可。
- 表示ルール: メモクラスタ距離 8m、遺跡解読距離 45m、メモマーカー表示 zoom >= 16.3、遺跡マーカー表示 zoom >= 15.3、初期ズームは `RetroConstants.mapZoom`。
- 永続化: ネイティブはローカル SQLite ファイル、web は wasm + IndexedDB。`MapRepository` を介して UI と永続化を分離している。

仕様変更時は `lib/features/map/retro_walk_map_page.dart` を起点に、`lib/data/repositories/map_repository.dart` / `sqlite_map_repository.dart` / `lib/models/*.dart` を併読する。

## 1. 最初の判断表

| やりたいこと | まず読むファイル | だいたい次に読むファイル |
| --- | --- | --- |
| アプリ全体の仕様を知る | `docs/REPOSITORY_MAP.md` | `lib/features/map/retro_walk_map_page.dart` |
| アプリ起動点を知る | `lib/main.dart` | `lib/app/app.dart` |
| テーマ変更 | `lib/app/theme/retro_theme.dart` | `lib/core/constants/retro_constants.dart` |
| 地図UI変更 | `lib/features/map/retro_walk_map_page.dart` | `lib/features/map/widgets/retro_markers.dart` |
| ダイアログ変更 | `lib/features/map/dialogs/retro_dialogs.dart` | `lib/features/map/retro_walk_map_page.dart` |
| メモ保存処理変更 | `lib/data/repositories/sqlite_map_repository.dart` | `lib/models/memo_pin.dart` |
| 遺跡保存処理変更 | `lib/data/repositories/sqlite_map_repository.dart` | `lib/models/ruin_spot.dart` |
| DB初期化/接続先変更 | `lib/data/database/database_factory.dart` | `lib/data/database/database_factory_native.dart`, `lib/data/database/database_factory_web.dart` |
| 初期遺跡データ変更 | `assets/data/ruins.json` | `lib/data/seed/seed_ruins_loader.dart` |
| 新しい永続化項目追加 | `lib/data/repositories/map_repository.dart` | `lib/data/repositories/sqlite_map_repository.dart` |
| 位置情報まわり変更 | `lib/features/map/retro_walk_map_page.dart` | なし |
| マーカーデザイン変更 | `lib/features/map/widgets/retro_markers.dart` | `lib/core/constants/retro_constants.dart` |
| テスト修正 | `test/widget_test.dart` | 対象機能の実装ファイル |

## 2. レイヤ構成

### Entry
- `lib/main.dart`
  - `RetroWalkMapApp` を起動するだけ。

### App Shell
- `lib/app/app.dart`
  - `MaterialApp` 構築。
  - `MapRepository` を注入。
- `lib/app/theme/retro_theme.dart`
  - アプリ共通テーマ。
  - `buildRetroTextStyle()` はダイアログやパネルの共通文字スタイル。

### Core
- `lib/core/constants/retro_constants.dart`
  - 色、ズーム値、距離閾値、マップ演出定数。
- `lib/core/utils/geo_utils.dart`
  - メートル単位オフセットを緯度経度へ変換。

### Models
- `lib/models/memo_pin.dart`
  - メモ1件。
- `lib/models/memo_cluster.dart`
  - 近接メモのクラスタ。
- `lib/models/ruin_spot.dart`
  - 遺跡1件。
  - seed JSON の読み込み口もここ。

### Data
- `lib/data/repositories/map_repository.dart`
  - UI が依存する抽象インターフェース。
- `lib/data/repositories/sqlite_map_repository.dart`
  - SQLite 実装本体。
  - テーブル作成、seed投入、CRUD を持つ。
- `lib/data/database/database_factory.dart`
  - プラットフォーム別DB接続の分岐入口。
- `lib/data/database/database_factory_native.dart`
  - ネイティブ用 SQLite ファイルDB。
- `lib/data/database/database_factory_web.dart`
  - Web 用 DB 接続。
- `lib/data/seed/seed_ruins_loader.dart`
  - `assets/data/ruins.json` を読み込み、衛星遺跡を展開。

### Feature: Map
- `lib/features/map/retro_walk_map_page.dart`
  - 画面の司令塔。
  - 状態管理、位置追従、地図描画、メモ/遺跡操作、パネルUIを持つ。
  - まずここを読めば画面全体の流れが分かる。
- `lib/features/map/dialogs/retro_dialogs.dart`
  - メモ追加、削除確認、遺跡追加、遺跡図鑑などのダイアログ群。
- `lib/features/map/widgets/retro_markers.dart`
  - プレイヤー、メモ、クラスタ、遺跡マーカーの見た目だけを持つ。

### Assets / Tests
- `assets/data/ruins.json`
  - 初期遺跡データ本体。ソース直書きではなくここを編集する。
- `test/widget_test.dart`
  - 最低限の起動確認。

## 3. 依存の向き

基本ルールは下向き依存のみ。

`main.dart`
-> `app/`
-> `features/`
-> `data/` + `models/`
-> `core/`

補足:
- `features/map/retro_walk_map_page.dart` は `MapRepository` 抽象に依存する。
- SQLite 実装は `sqlite_map_repository.dart` に閉じ込めてある。
- 初期遺跡データは `assets/data/ruins.json` にあり、UIは直接知らない。

## 4. 変更時の最小読込セット

### メモ機能だけ触る
- `lib/features/map/retro_walk_map_page.dart`
- `lib/features/map/dialogs/retro_dialogs.dart`
- `lib/data/repositories/map_repository.dart`
- `lib/data/repositories/sqlite_map_repository.dart`
- `lib/models/memo_pin.dart`

### 遺跡機能だけ触る
- `lib/features/map/retro_walk_map_page.dart`
- `lib/features/map/dialogs/retro_dialogs.dart`
- `lib/data/repositories/sqlite_map_repository.dart`
- `lib/models/ruin_spot.dart`
- `assets/data/ruins.json`
- `lib/data/seed/seed_ruins_loader.dart`

### 見た目だけ触る
- `lib/app/theme/retro_theme.dart`
- `lib/core/constants/retro_constants.dart`
- `lib/features/map/widgets/retro_markers.dart`
- `lib/features/map/retro_walk_map_page.dart`

### DBだけ触る
- `lib/data/repositories/map_repository.dart`
- `lib/data/repositories/sqlite_map_repository.dart`
- `lib/data/database/database_factory*.dart`
- 必要なら `lib/models/*.dart`

## 5. 読まなくてよいことが多いファイル

- `test/widget_test.dart`
  - UI改修で表示崩れが疑われるときだけ読む。
- `lib/core/utils/geo_utils.dart`
  - seed 遺跡の周辺展開を変えるときだけ読む。
- `lib/main.dart`
  - 起動点確認以外ではほぼ不要。

## 6. このリポジトリの設計意図

- UI と永続化を分離する。
- 初期遺跡データはコードではなく asset 管理にする。
- 画面側は `MapRepository` 抽象だけを見ればよい形にする。
- AI が新機能追加時に「1ファイル丸読み」を避けられるようにする。
