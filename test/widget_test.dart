import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:map_app/app/app.dart';
import 'package:map_app/data/repositories/map_repository.dart';
import 'package:map_app/models/memo_pin.dart';
import 'package:map_app/models/ruin_spot.dart';

void main() {
  testWidgets('app renders title', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 930));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RetroWalkMapApp(repository: _FakeMapRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('パネルを開く'));
    await tester.pumpAndSettle();

    expect(find.text('レトログ'), findsWidgets);
  });

  testWidgets(
    'memo add dialog and artificial ruin add dialog can be cancelled without FlutterError or dependents assertion',
    (WidgetTester tester) async {
      await _pumpApp(tester);

      await _openAndCancelDialog(
        tester,
        openLabel: 'メモを追加',
        cancelLabel: 'キャンセル',
      );

      await _openAndCancelDialog(
        tester,
        openLabel: '人工遺跡を追加',
        cancelLabel: 'キャンセル',
      );

      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 930));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    RetroWalkMapApp(repository: _FakeMapRepository()),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('パネルを開く'));
  await tester.pumpAndSettle();
}

Future<void> _openAndCancelDialog(
  WidgetTester tester, {
  required String openLabel,
  required String cancelLabel,
}) async {
  await tester.tap(find.text(openLabel));
  await tester.pumpAndSettle();

  expect(find.text(cancelLabel), findsWidgets);

  await tester.tap(find.text(cancelLabel).first);
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
}

class _FakeMapRepository implements MapRepository {
  @override
  Future<void> initialize() async {}

  @override
  Future<List<MemoPin>> loadMemos() async => const [];

  @override
  Future<List<RuinSpot>> loadRuins() async => const [];

  @override
  Future<MemoPin> createMemo({
    required double lat,
    required double lng,
    required String text,
    required DateTime createdAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RuinSpot> createArtificialRuin({
    required double lat,
    required double lng,
    required String inscription,
    required int obscuredStart,
    required int obscuredEnd,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMemo(String id) async {}

  @override
  Future<void> deleteRuin(String id) async {}
}
