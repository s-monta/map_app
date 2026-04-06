# Flutter Map App Prototype

Flutter SDK が入っている環境で、まず Web で確認する前提のプロトタイプです。

## 実行

```bash
flutter pub get
flutter run -d chrome
```

## 内容

- 依存なしの純 Flutter 実装
- 地図SDKなしでも試せる地図風UI
- マーカー選択、カテゴリ絞り込み、ルート表示、現在地風パルス
- 後で `flutter_map` や Google Maps 系に差し替えやすい構成
