import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RetroConstants {
  static const double pixel6aAspectRatio = 1080 / 2400;
  static const LatLng tokyoStation = LatLng(35.681236, 139.767125);

  static const double mapZoom = 17;
  static const double memoMarkerMinZoom = 16.3;
  static const double ruinMarkerMinZoom = 15.3;
  static const double memoClusterDistanceMeters = 8;
  static const double ruinUnlockDistanceMeters = 45;

  /// 画面下部の開閉UIに共通で使うスペーシング。
  /// Android のシステムナビゲーションバーとの干渉を避けるため、
  /// 最低限の下端マージンをここでまとめて管理する。
  static const double bottomSheetEdgeMargin = 12;

  /// 下部開閉UIの折りたたみ時の浮かせ量。
  /// 地図上に重ねるため、下端から少し持ち上げて表示する。
  static const double collapsedPanelBottomOffset = 16;

  /// 展開時パネルの高さ。
  static const double expandedPanelHeight = 260;

  /// 地図上に重ねるUI全般の共通パディング。
  static const double mapOverlayPadding = 12;

  /// ボタン群やパネル内コンテンツの共通余白。
  static const double mapOverlayContentSpacing = 8;

  /// 下部開閉UIの最小安全マージン。
  /// システムナビゲーションとの衝突回避用の下端余白として使う。
  static const double safeBottomInsetMargin = 8;

  static const Color retroButtonText = Color(0xFFF7E8C6);
  static const Color retroMemoButton = Color(0xFFA56A2A);
  static const Color retroRuinAddButton = Color(0xFF3C6E57);
  static const Color retroArchiveButton = Color(0xFF5E4A2F);
  static const Color retroLocationButton = Color(0xFF4E6F9A);
  static const Color retroButtonBorder = Color(0xFFFFE088);
  static const List<double> retroArcadeMatrix = [
    0.84,
    0.14,
    0.08,
    0,
    6,
    0.12,
    0.86,
    0.12,
    0,
    4,
    0.08,
    0.16,
    0.74,
    0,
    2,
    0,
    0,
    0,
    1,
    0,
  ];
}
