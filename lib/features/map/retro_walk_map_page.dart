import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/retro_theme.dart';
import '../../core/constants/retro_constants.dart';
import '../../data/repositories/map_repository.dart';
import '../../models/favorite_pin.dart';
import '../../models/memo_cluster.dart';
import '../../models/memo_pin.dart';
import '../../models/ruin_spot.dart';
import 'dialogs/retro_dialogs.dart';
import 'widgets/retro_markers.dart';

class RetroWalkMapPage extends StatefulWidget {
  const RetroWalkMapPage({
    super.key,
    required this.repository,
  });

  final MapRepository repository;

  @override
  State<RetroWalkMapPage> createState() => _RetroWalkMapPageState();
}

class _RetroWalkMapPageState extends State<RetroWalkMapPage> {
  final MapController _mapController = MapController();
  final List<MemoPin> _memoPins = [];
  final List<RuinSpot> _ruins = [];
  final List<FavoritePin> _favoritePins = [];
  final Set<String> _decodedRuinIds = <String>{};

  StreamSubscription<Position>? _positionSubscription;
  LatLng _currentLatLng = RetroConstants.tokyoStation;
  double _currentZoom = RetroConstants.mapZoom;
  String _statusText = '位置情報を準備中...';
  bool _mapReady = false;
  bool _panelExpanded = false;
  bool _dataLoaded = false;
  bool _hasCurrentLocation = false;

  List<RuinSpot> get _allRuins => _ruins;
  int get _artificialRuinCount =>
      _ruins.where((ruin) => ruin.isArtificial).length;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await widget.repository.initialize();
      final memos = await widget.repository.loadMemos();
      final ruins = await widget.repository.loadRuins();
      final favorites = await widget.repository.loadFavorites();
      if (!mounted) {
        return;
      }

      setState(() {
        _memoPins
          ..clear()
          ..addAll(memos);
        _ruins
          ..clear()
          ..addAll(ruins);
        _favoritePins
          ..clear()
          ..addAll(favorites);
        _dataLoaded = true;
        _statusText = '記録DBを読み込みました';
      });

      final nearby = _collectNearbyRuins(_currentLatLng);
      if (nearby.isNotEmpty && mounted) {
        setState(() {
          _statusText = '遺跡を解読: ${nearby.map((ruin) => ruin.name).join('、')}';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dataLoaded = true;
        _statusText = '記録DBの読み込みに失敗しました';
      });
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _statusText = '位置情報サービスがOFFです';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _statusText = '位置情報の許可が必要です';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _statusText = '端末の設定で位置情報を許可してください';
        });
        return;
      }

      final initialPosition = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }
      _updatePlayerPosition(initialPosition, note: '現在地を取得しました');

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        ),
      ).listen(
        (position) {
          _updatePlayerPosition(position, note: '現在地に追従中');
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _statusText = '位置情報の取得に失敗しました';
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusText = '位置情報を取得できませんでした';
        });
      }
    }
  }

  void _updatePlayerPosition(Position position, {required String note}) {
    final nextLatLng = LatLng(position.latitude, position.longitude);
    final nearby = _collectNearbyRuins(nextLatLng);
    if (!mounted) {
      return;
    }

    setState(() {
      _currentLatLng = nextLatLng;
      _hasCurrentLocation = true;
      _statusText = nearby.isNotEmpty
          ? '遺跡を解読: ${nearby.map((ruin) => ruin.name).join('、')}'
          : note;
    });

    if (_mapReady) {
      _mapController.move(nextLatLng, RetroConstants.mapZoom);
    }
  }

  void _centerMapOnCurrentLocation() {
    if (!_mapReady || !_hasCurrentLocation) {
      return;
    }
    _mapController.move(_currentLatLng, _currentZoom);
    setState(() {
      _statusText = '地図を現在地に戻しました';
    });
  }

  List<RuinSpot> _collectNearbyRuins(LatLng origin) {
    final unlocked = <RuinSpot>[];
    for (final ruin in _allRuins) {
      if (_decodedRuinIds.contains(ruin.id)) {
        continue;
      }
      final distance = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        ruin.position.latitude,
        ruin.position.longitude,
      );
      if (distance <= RetroConstants.ruinUnlockDistanceMeters) {
        _decodedRuinIds.add(ruin.id);
        unlocked.add(ruin);
      }
    }
    return unlocked;
  }

  bool _isRuinDecoded(RuinSpot ruin) => _decodedRuinIds.contains(ruin.id);

  double _distanceToRuinMeters(RuinSpot ruin) {
    return Geolocator.distanceBetween(
      _currentLatLng.latitude,
      _currentLatLng.longitude,
      ruin.position.latitude,
      ruin.position.longitude,
    );
  }

  bool _shouldUseFramedPreview() {
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => false,
      _ => true,
    };
  }

  String _glitchText(String input) {
    const garbled = ['#', '%', '@', '?', '※', '▒', '▓', '■', '◇', '･', '*'];
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final isSpace = RegExp(r'\s').hasMatch(char);
      final isPunctuation = RegExp(r'[、。,.!?！？：:・「」『』（）()〜-]').hasMatch(char);
      buffer.write(
        isSpace || isPunctuation ? char : garbled[rune % garbled.length],
      );
    }
    return buffer.toString();
  }

  int _normalizedObscuredStart(RuinSpot ruin, int length) {
    final start = ruin.obscuredStart;
    if (start == null) {
      return 0;
    }
    return start.clamp(0, length);
  }

  int _normalizedObscuredEnd(RuinSpot ruin, int length) {
    final end = ruin.obscuredEnd;
    if (end == null) {
      return length;
    }
    return end.clamp(0, length);
  }

  ({int start, int end}) _obscuredRangeFor(RuinSpot ruin) {
    final length = ruin.inscription.length;
    if (length == 0) {
      return (start: 0, end: 0);
    }

    var start = _normalizedObscuredStart(ruin, length);
    var end = _normalizedObscuredEnd(ruin, length);

    if (end < start) {
      final temp = start;
      start = end;
      end = temp;
    }

    if (start == end) {
      if (start >= length) {
        start = 0;
        end = length;
      } else {
        end = (start + 1).clamp(0, length);
      }
    }

    return (start: start, end: end);
  }

  String _maskedInscription(RuinSpot ruin, {required bool decoded}) {
    if (decoded || ruin.inscription.isEmpty) {
      return ruin.inscription;
    }
    final range = _obscuredRangeFor(ruin);
    if (range.start >= range.end) {
      return ruin.inscription;
    }
    final head = ruin.inscription.substring(0, range.start);
    final obscured = ruin.inscription.substring(range.start, range.end);
    final tail = ruin.inscription.substring(range.end);
    return '$head${_glitchText(obscured)}$tail';
  }

  Future<void> _addMemoAtCurrentLocation() async {
    final memoText = await showAddMemoDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
    );
    if (!mounted || memoText == null || memoText.isEmpty) {
      return;
    }

    final memo = await widget.repository.createMemo(
      lat: _currentLatLng.latitude,
      lng: _currentLatLng.longitude,
      text: memoText,
      createdAt: DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _memoPins.insert(0, memo);
      _statusText = '現在地にメモを残しました';
    });
  }

  Future<void> _addFavoriteAtCurrentLocation() async {
    if (!_hasCurrentLocation) {
      return;
    }

    final favorite = await widget.repository.createFavorite(
      lat: _currentLatLng.latitude,
      lng: _currentLatLng.longitude,
      createdAt: DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _favoritePins.insert(0, favorite);
      _statusText = '現在地をお気に入りに追加しました';
    });
  }

  Future<void> _deleteMemo(MemoPin memo) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      title: 'メモを削除しますか？',
    );
    if (!confirmed) {
      return;
    }
    await widget.repository.deleteMemo(memo.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _memoPins.removeWhere((item) => item.id == memo.id);
      _statusText = 'メモを削除しました';
    });
  }

  Future<void> _showMemoDetails(MemoPin memo) async {
    await showMemoDetailsDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      memo: memo,
      onDelete: () => _deleteMemo(memo),
    );
  }

  Future<void> _showMemoCluster(MemoCluster cluster) async {
    await showMemoClusterDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      cluster: cluster,
      onOpenMemo: _showMemoDetails,
      onDeleteMemo: _deleteMemo,
    );
  }

  Future<void> _addArtificialRuinAtCurrentLocation() async {
    final created = await showAddArtificialRuinDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      glitchText: _glitchText,
    );
    if (!mounted || created == null) {
      return;
    }

    final ruin = await widget.repository.createArtificialRuin(
      lat: _currentLatLng.latitude,
      lng: _currentLatLng.longitude,
      inscription: created.inscription,
      obscuredStart: created.obscuredStart,
      obscuredEnd: created.obscuredEnd,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _ruins.add(ruin);
      _statusText = '人工遺跡を現在地に追加しました';
    });
  }

  Future<void> _deleteArtificialRuin(RuinSpot ruin) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      title: '人工遺跡を削除しますか？',
    );
    if (!confirmed) {
      return;
    }
    await widget.repository.deleteRuin(ruin.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _ruins.removeWhere((item) => item.id == ruin.id);
      _decodedRuinIds.remove(ruin.id);
      _statusText = '人工遺跡を削除しました';
    });
  }

  Future<void> _showRuinDetails(RuinSpot ruin) async {
    final shouldDecodeNow =
        _distanceToRuinMeters(ruin) <= RetroConstants.ruinUnlockDistanceMeters &&
            !_isRuinDecoded(ruin);
    if (shouldDecodeNow) {
      setState(() {
        _decodedRuinIds.add(ruin.id);
        _statusText = '遺跡「${ruin.name}」の全文を解読しました';
      });
    }

    final decoded = _isRuinDecoded(ruin);
    await showRuinDetailsDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      ruin: ruin,
      shownBody: _maskedInscription(
        ruin,
        decoded: decoded,
      ),
      decoded: decoded,
      onDelete: ruin.isArtificial ? () => _deleteArtificialRuin(ruin) : null,
    );
  }

  Future<void> _openRuinArchive() async {
    await showRuinArchiveDialog(
      context: context,
      retroTextStyle: buildRetroTextStyle,
      ruins: _allRuins,
      decodedRuinIds: _decodedRuinIds,
      maskedInscription: _maskedInscription,
    );
  }

  List<MemoCluster> _buildMemoClusters(List<MemoPin> memos) {
    final clusters = <MemoCluster>[];
    for (final memo in memos) {
      MemoCluster? found;
      for (final cluster in clusters) {
        final distance = Geolocator.distanceBetween(
          memo.position.latitude,
          memo.position.longitude,
          cluster.center.latitude,
          cluster.center.longitude,
        );
        if (distance <= RetroConstants.memoClusterDistanceMeters) {
          found = cluster;
          break;
        }
      }
      if (found == null) {
        clusters.add(MemoCluster(center: memo.position, memos: [memo]));
      } else {
        found.memos.add(memo);
      }
    }
    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    final useFramedPreview = _shouldUseFramedPreview();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF4B4457),
        child: useFramedPreview
            ? Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 420, maxHeight: 930),
                  child: AspectRatio(
                    aspectRatio: RetroConstants.pixel6aAspectRatio,
                    child: _buildGameSurface(
                      useFramedPreview: true,
                      bottomInset: bottomInset,
                    ),
                  ),
                ),
              )
            : _buildGameSurface(
                useFramedPreview: false,
                bottomInset: bottomInset,
              ),
      ),
    );
  }

  Widget _buildGameSurface({
    required bool useFramedPreview,
    required double bottomInset,
  }) {
    final panelBottomOffset =
        _panelExpanded ? bottomInset + 12 : bottomInset + 18;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A2C),
        borderRadius: useFramedPreview ? BorderRadius.circular(32) : null,
        boxShadow: useFramedPreview
            ? const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 30,
                  offset: Offset(0, 18),
                ),
              ]
            : null,
        border: useFramedPreview
            ? Border.all(color: const Color(0xFF3A2F5A), width: 3)
            : null,
      ),
      child: ClipRRect(
        borderRadius:
            useFramedPreview ? BorderRadius.circular(28) : BorderRadius.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMapArea(),
            if (useFramedPreview) _buildPhoneBezelDecor(),
            _buildBottomOverlay(panelBottomOffset: panelBottomOffset),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    final memoClusters = _buildMemoClusters(_memoPins);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter:
              const ColorFilter.matrix(RetroConstants.retroArcadeMatrix),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng,
              initialZoom: RetroConstants.mapZoom,
              minZoom: 4,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
              onMapReady: () {
                _mapReady = true;
                _currentZoom = RetroConstants.mapZoom;
                _mapController.move(_currentLatLng, RetroConstants.mapZoom);
              },
              onPositionChanged: (position, _) {
                final zoom = position.zoom;
                if (zoom != null && (zoom - _currentZoom).abs() > 0.02 && mounted) {
                  setState(() {
                    _currentZoom = zoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.map_app',
              ),
              MarkerLayer(
                markers: [
                  ..._favoritePins.map(
                    (favorite) => Marker(
                      point: favorite.position,
                      width: 50,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: Transform.translate(
                        offset: const Offset(0, -10),
                        child: const RetroFavoriteMarker(),
                      ),
                    ),
                  ),
                  Marker(
                    point: _currentLatLng,
                    width: 48,
                    height: 62,
                    alignment: Alignment.topCenter,
                    child: const RetroPlayerMarker(),
                  ),
                  ...memoClusters.map(
                    (cluster) => Marker(
                      point: cluster.center,
                      width: 54,
                      height: 66,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          if (cluster.memos.length == 1) {
                            _showMemoDetails(cluster.memos.first);
                          } else {
                            _showMemoCluster(cluster);
                          }
                        },
                        child: cluster.memos.length == 1
                            ? const RetroMemoMarker()
                            : RetroMemoClusterMarker(count: cluster.memos.length),
                      ),
                    ),
                  ),
                  ..._allRuins.map(
                    (ruin) => Marker(
                      point: ruin.position,
                      width: 50,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showRuinDetails(ruin),
                        child: RetroRuinMarker(decoded: _isRuinDecoded(ruin)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: 0.24,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFC5B5B),
                    Color(0xFF35D3C7),
                    Color(0xFFFFD469),
                  ],
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  Color(0x00000000),
                  Color(0x55000000),
                ],
              ),
            ),
          ),
        ),
        if (!_dataLoaded)
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xCC151023),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE088), width: 2),
                ),
                child: Text(
                  '記録DBを読み込み中...',
                  style: buildRetroTextStyle(
                    color: const Color(0xFFFDF8E8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneBezelDecor() {
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 112,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xCC1A1330),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay({required double panelBottomOffset}) {
    final textStyle = buildRetroTextStyle(
      color: const Color(0xFFFDF8E8),
      fontSize: 15,
      height: 1.7,
    );

    final panelWidthMargin = _panelExpanded ? 14.0 : 14.0;
    final collapsedWidthMargin = _panelExpanded ? 14.0 : 16.0;

    return Positioned(
      left: panelWidthMargin,
      right: panelWidthMargin,
      bottom: panelBottomOffset,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _panelExpanded
            ? _buildExpandedPanel(textStyle)
            : _buildCollapsedPanel(
                bottomInset: panelBottomOffset,
                horizontalMargin: collapsedWidthMargin,
              ),
      ),
    );
  }

  Widget _buildExpandedPanel(TextStyle textStyle) {
    final canCenterMap = _mapReady && _hasCurrentLocation;
    final canAddFavorite = _hasCurrentLocation;

    return SizedBox(
      key: const ValueKey('expanded-panel'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC151023),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFE088), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            minimum: const EdgeInsets.only(bottom: 2),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPanelHeader(textStyle),
                    const SizedBox(height: 10),
                    Text(
                      '緯度 ${_currentLatLng.latitude.toStringAsFixed(6)}',
                      style: textStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '経度 ${_currentLatLng.longitude.toStringAsFixed(6)}',
                      style: textStyle,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _addMemoAtCurrentLocation,
                            style: _panelButtonStyle(
                              textStyle,
                              backgroundColor: RetroConstants.retroMemoButton,
                            ),
                            icon: const Icon(
                              Icons.note_add_rounded,
                              size: 18,
                            ),
                            label: Text('メモ ${_memoPins.length}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _openRuinArchive,
                            style: _panelButtonStyle(
                              textStyle,
                              backgroundColor: RetroConstants.retroArchiveButton,
                            ),
                            icon: const Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                            ),
                            label: Text(
                              '図鑑 ${_decodedRuinIds.length}/${_allRuins.length}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canCenterMap ? _centerMapOnCurrentLocation : null,
                        style: _panelButtonStyle(
                          textStyle,
                          backgroundColor: RetroConstants.retroMemoButton,
                        ),
                        icon: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                        ),
                        label: const Text('現在地へ'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _addArtificialRuinAtCurrentLocation,
                        style: _panelButtonStyle(
                          textStyle,
                          backgroundColor: RetroConstants.retroRuinAddButton,
                        ),
                        icon: const Icon(
                          Icons.add_location_alt_rounded,
                          size: 18,
                        ),
                        label: Text('人工遺跡を追加 $_artificialRuinCount'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canAddFavorite ? _addFavoriteAtCurrentLocation : null,
                        style: _panelButtonStyle(
                          textStyle,
                          backgroundColor: RetroConstants.retroArchiveButton,
                        ),
                        icon: const Icon(
                          Icons.star_rounded,
                          size: 18,
                        ),
                        label: Text('お気に入り ${_favoritePins.length}'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(
                        fontSize: 12,
                        color: const Color(0xFFE5D8FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _panelButtonStyle(
    TextStyle textStyle, {
    required Color backgroundColor,
  }) {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      backgroundColor: backgroundColor,
      foregroundColor: RetroConstants.retroButtonText,
      side: const BorderSide(
        color: RetroConstants.retroButtonBorder,
        width: 2,
      ),
      textStyle: textStyle.copyWith(
        fontSize: 11,
        color: RetroConstants.retroButtonText,
        shadows: const [],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildCollapsedPanel({
    required double bottomInset,
    required double horizontalMargin,
  }) {
    final collapsedStyle = buildRetroTextStyle(
      color: const Color(0xFFFDF8E8),
      fontSize: 12,
      height: 1.2,
    );

    return SizedBox(
      key: const ValueKey('collapsed-panel'),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: EdgeInsets.only(bottom: bottomInset > 0 ? 6 : 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _panelExpanded = true;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
              decoration: BoxDecoration(
                color: const Color(0xCC151023),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFE088), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Color(0xFFFFE088),
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'パネルを開く',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: collapsedStyle.copyWith(
                          fontSize: 11,
                          color: const Color(0xFFF7E8C6),
                          shadows: const [],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_memoPins.length} / ${_allRuins.length}',
                      style: collapsedStyle.copyWith(
                        fontSize: 10,
                        color: const Color(0xFFE5D8FF),
                        shadows: const [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader(TextStyle textStyle) {
    return Row(
      children: [
        Text(
          'レトログ',
          style: textStyle.copyWith(
            fontSize: 18,
            color: const Color(0xFF6AF0D4),
          ),
        ),
        const Spacer(),
        InkResponse(
          onTap: () {
            setState(() {
              _panelExpanded = false;
            });
          },
          radius: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x332F2A45),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFE088), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFFFFE088),
                ),
                const SizedBox(width: 4),
                Text(
                  '閉じる',
                  style: textStyle.copyWith(
                    fontSize: 10,
                    color: const Color(0xFFF7E8C6),
                    shadows: const [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
