import 'package:flutter/material.dart';

import '../../../app/theme/retro_theme.dart';
import '../../../core/constants/retro_constants.dart';
import '../../../models/memo_cluster.dart';
import '../../../models/memo_pin.dart';
import '../../../models/ruin_spot.dart';

Future<String?> showAddMemoDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return _AddMemoDialogContent(
        retroTextStyle: retroTextStyle,
      );
    },
  );
}

class _AddMemoDialogContent extends StatefulWidget {
  const _AddMemoDialogContent({
    required this.retroTextStyle,
  });

  final RetroTextStyleBuilder retroTextStyle;

  @override
  State<_AddMemoDialogContent> createState() => _AddMemoDialogContentState();
}

class _AddMemoDialogContentState extends State<_AddMemoDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? result]) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.retroTextStyle(
      color: const Color(0xFFFDF8E8),
      fontSize: 14,
      height: 1.6,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1A2C),
      title: Text(
        '現在地メモを残す',
        style: style.copyWith(fontSize: 16, height: 1.4),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        style: style,
        decoration: InputDecoration(
          hintText: 'ここでの出来事をメモ',
          hintStyle: style.copyWith(color: const Color(0xFF8A7FA3)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(),
          child: Text(
            'キャンセル',
            style: style.copyWith(
              fontSize: 12,
              color: const Color(0xFFD1C8E5),
              shadows: const [],
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              _close(text);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: RetroConstants.retroMemoButton,
            foregroundColor: RetroConstants.retroButtonText,
            side: const BorderSide(
              color: RetroConstants.retroButtonBorder,
              width: 2,
            ),
          ),
          child: Text(
            '保存',
            style: style.copyWith(
              fontSize: 12,
              color: RetroConstants.retroButtonText,
              shadows: const [],
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
  required String title,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final style = retroTextStyle(
        color: const Color(0xFFFDF8E8),
        fontSize: 14,
        height: 1.6,
      );
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1A2C),
        title: Text(title, style: style.copyWith(fontSize: 16)),
        content: Text(
          'この操作は取り消せません。',
          style: style.copyWith(fontSize: 12, color: const Color(0xFFD1C8E5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'キャンセル',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
                shadows: const [],
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: Text(
              '削除',
              style: style.copyWith(
                fontSize: 12,
                color: RetroConstants.retroButtonText,
                shadows: const [],
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8E3A3A),
              foregroundColor: RetroConstants.retroButtonText,
              side: const BorderSide(
                color: RetroConstants.retroButtonBorder,
                width: 2,
              ),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<void> showMemoDetailsDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
  required MemoPin memo,
  required Future<void> Function() onDelete,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      final style = retroTextStyle(
        color: const Color(0xFFFDF8E8),
        fontSize: 14,
        height: 1.6,
      );
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1A2C),
        title: Text(
          'メモ',
          style: style.copyWith(fontSize: 16, height: 1.4),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(memo.text, style: style),
            const SizedBox(height: 12),
            Text(
              '緯度 ${memo.position.latitude.toStringAsFixed(6)}',
              style: style.copyWith(fontSize: 12),
            ),
            Text(
              '経度 ${memo.position.longitude.toStringAsFixed(6)}',
              style: style.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              '${memo.createdAt.month}/${memo.createdAt.day} '
              '${memo.createdAt.hour.toString().padLeft(2, '0')}:${memo.createdAt.minute.toString().padLeft(2, '0')}',
              style: style.copyWith(
                fontSize: 11,
                color: const Color(0xFFD1C8E5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await onDelete();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Color(0xFFFFB8B8),
            ),
            label: Text(
              '削除',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFFFB8B8),
                shadows: const [],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '閉じる',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
                shadows: const [],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showMemoClusterDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
  required MemoCluster cluster,
  required Future<void> Function(MemoPin memo) onOpenMemo,
  required Future<void> Function(MemoPin memo) onDeleteMemo,
}) async {
  final ordered = [...cluster.memos]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  await showDialog<void>(
    context: context,
    builder: (context) {
      final style = retroTextStyle(
        color: const Color(0xFFFDF8E8),
        fontSize: 14,
        height: 1.6,
      );
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1A2C),
        title: Text(
          '重なったメモ ${ordered.length}件',
          style: style.copyWith(fontSize: 16),
        ),
        content: SizedBox(
          width: 340,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final memo = ordered[index];
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x332F2A45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7D7199)),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    memo.text.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style.copyWith(fontSize: 12),
                  ),
                  subtitle: Text(
                    '${memo.createdAt.month}/${memo.createdAt.day} '
                    '${memo.createdAt.hour.toString().padLeft(2, '0')}:${memo.createdAt.minute.toString().padLeft(2, '0')}',
                    style: style.copyWith(
                      fontSize: 10,
                      color: const Color(0xFFD1C8E5),
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await onOpenMemo(memo);
                  },
                  trailing: IconButton(
                    onPressed: () async {
                      await onDeleteMemo(memo);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFFB8B8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '閉じる',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
                shadows: const [],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<({String inscription, int obscuredStart, int obscuredEnd})?>
    showAddArtificialRuinDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
  required String Function(String text) glitchText,
}) async {
  return showDialog<({String inscription, int obscuredStart, int obscuredEnd})>(
    context: context,
    builder: (context) {
      return _AddArtificialRuinDialogContent(
        retroTextStyle: retroTextStyle,
        glitchText: glitchText,
      );
    },
  );
}

class _AddArtificialRuinDialogContent extends StatefulWidget {
  const _AddArtificialRuinDialogContent({
    required this.retroTextStyle,
    required this.glitchText,
  });

  final RetroTextStyleBuilder retroTextStyle;
  final String Function(String text) glitchText;

  @override
  State<_AddArtificialRuinDialogContent> createState() =>
      _AddArtificialRuinDialogContentState();
}

class _AddArtificialRuinDialogContentState
    extends State<_AddArtificialRuinDialogContent> {
  late final TextEditingController _inscriptionController;
  late final FocusNode _focusNode;
  int _obscuredStart = 1;
  int _obscuredEnd = 1;

  @override
  void initState() {
    super.initState();
    _inscriptionController = TextEditingController();
    _focusNode = FocusNode();
    _inscriptionController.addListener(_syncRangeWithText);
  }

  @override
  void dispose() {
    _inscriptionController.removeListener(_syncRangeWithText);
    _inscriptionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _normalizeInput(String input) {
    final buffer = StringBuffer();
    var hasVisible = false;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final normalized = _normalizeChar(char);
      if (normalized == null) {
        continue;
      }
      if (normalized.trim().isEmpty && !hasVisible) {
        continue;
      }
      buffer.write(normalized);
      if (normalized.trim().isNotEmpty) {
        hasVisible = true;
      }
    }
    return buffer.toString().trim();
  }

  String? _normalizeChar(String char) {
    const fullWidthDigits = {
      '０': '0',
      '１': '1',
      '２': '2',
      '３': '3',
      '４': '4',
      '５': '5',
      '６': '6',
      '７': '7',
      '８': '8',
      '９': '9',
    };
    if (fullWidthDigits.containsKey(char)) {
      return fullWidthDigits[char];
    }
    if (RegExp(r'[0-9]').hasMatch(char)) {
      return char;
    }
    if (RegExp(r'[\s　]').hasMatch(char)) {
      return ' ';
    }
    return null;
  }

  int? _parseOneBasedIndex(String raw, {required int maxInclusive}) {
    final normalized = _normalizeInput(raw);
    if (normalized.isEmpty) return null;
    final value = int.tryParse(normalized);
    if (value == null) return null;
    if (value < 1 || value > maxInclusive) return null;
    return value;
  }

  void _syncRangeWithText() {
    if (!mounted) return;
    final text = _inscriptionController.text.trim();
    final maxLen = text.length;

    setState(() {
      if (maxLen < 2) {
        _obscuredStart = 1;
        _obscuredEnd = 1;
        return;
      }

      _obscuredStart = _obscuredStart.clamp(1, maxLen);
      _obscuredEnd = _obscuredEnd.clamp(1, maxLen);
      if (_obscuredStart > _obscuredEnd) {
        _obscuredEnd = _obscuredStart;
      }
    });
  }

  void _close([({String inscription, int obscuredStart, int obscuredEnd})? result]) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.retroTextStyle(
      color: const Color(0xFFFDF8E8),
      fontSize: 14,
      height: 1.6,
    );

    final inscription = _normalizeInput(_inscriptionController.text);
    final maxLen = inscription.length;
    final startValid = maxLen >= 2 && _obscuredStart >= 1 && _obscuredStart <= maxLen;
    final endValid = maxLen >= 2 && _obscuredEnd >= 1 && _obscuredEnd <= maxLen;
    final canSave = startValid && endValid && _obscuredStart <= _obscuredEnd;

    final preview = canSave
        ? '${inscription.substring(0, _obscuredStart - 1)}'
            '${widget.glitchText(inscription.substring(_obscuredStart - 1, _obscuredEnd))}'
            '${inscription.substring(_obscuredEnd)}'
        : inscription;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1A2C),
      title: Text(
        '人工遺跡を追加',
        style: style.copyWith(fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '名前: 人工遺跡',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _inscriptionController,
              focusNode: _focusNode,
              maxLines: 4,
              autofocus: true,
              style: style,
              decoration: InputDecoration(
                hintText: '碑文テキスト（2文字以上）',
                hintStyle: style.copyWith(
                  color: const Color(0xFF8A7FA3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '読めない範囲を指定',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
              ),
            ),
            const SizedBox(height: 4),
            if (maxLen < 2)
              Text(
                '先に碑文を2文字以上入力してください。',
                style: style.copyWith(
                  fontSize: 11,
                  color: const Color(0xFFFFB067),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    values: RangeValues(
                      _obscuredStart.toDouble(),
                      _obscuredEnd.toDouble(),
                    ),
                    min: 1,
                    max: maxLen.toDouble(),
                    divisions: maxLen - 1,
                    labels: RangeLabels(
                      '$_obscuredStart',
                      '$_obscuredEnd',
                    ),
                    onChanged: (value) {
                      final start = value.start.round().clamp(1, maxLen);
                      final end = value.end.round().clamp(1, maxLen);
                      setState(() {
                        _obscuredStart = start;
                        _obscuredEnd = end < start ? start : end;
                      });
                    },
                  ),
                  Text(
                    '範囲: $_obscuredStart 〜 $_obscuredEnd 文字目（両端含む）',
                    style: style.copyWith(fontSize: 11),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'プレビュー',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              preview,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(),
          child: Text(
            'キャンセル',
            style: style.copyWith(
              fontSize: 12,
              color: const Color(0xFFD1C8E5),
              shadows: const [],
            ),
          ),
        ),
        FilledButton(
          onPressed: canSave
              ? () {
                  _close((
                    inscription: inscription,
                    obscuredStart: _obscuredStart,
                    obscuredEnd: _obscuredEnd,
                  ));
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: RetroConstants.retroRuinAddButton,
            foregroundColor: RetroConstants.retroButtonText,
            side: const BorderSide(
              color: RetroConstants.retroButtonBorder,
              width: 2,
            ),
          ),
          child: Text(
            '追加',
            style: style.copyWith(
              fontSize: 12,
              color: RetroConstants.retroButtonText,
              shadows: const [],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showRuinDetailsDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
  required RuinSpot ruin,
  required String shownBody,
  required bool decoded,
  required Future<void> Function()? onDelete,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      final style = retroTextStyle(
        color: const Color(0xFFFDF8E8),
        fontSize: 14,
        height: 1.7,
      );
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1A2C),
        title: Text(ruin.name, style: style.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shownBody, style: style),
            const SizedBox(height: 12),
            Text(
              decoded ? '解読済み' : '欠損部分は現地到達で解読できます。',
              style: style.copyWith(
                fontSize: 12,
                color:
                    decoded ? const Color(0xFF6AF0D4) : const Color(0xFFFFB067),
              ),
            ),
          ],
        ),
        actions: [
          if (onDelete != null)
            TextButton.icon(
              onPressed: () async {
                await onDelete();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Color(0xFFFFB8B8),
              ),
              label: Text(
                '削除',
                style: style.copyWith(
                  fontSize: 12,
                  color: const Color(0xFFFFB8B8),
                  shadows: const [],
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '閉じる',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
                shadows: const [],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showRuinArchiveDialog({
  required BuildContext context,
  required RetroTextStyleBuilder retroTextStyle,
  required List<RuinSpot> ruins,
  required Set<String> decodedRuinIds,
  required String Function(RuinSpot ruin, {required bool decoded})
      maskedInscription,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      final style = retroTextStyle(
        color: const Color(0xFFFDF8E8),
        fontSize: 14,
        height: 1.6,
      );
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1A2C),
        title: Text(
          '遺跡図鑑  ${decodedRuinIds.length}/${ruins.length}',
          style: style.copyWith(fontSize: 16),
        ),
        content: SizedBox(
          width: 340,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: ruins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ruin = ruins[index];
              final decoded = decodedRuinIds.contains(ruin.id);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: decoded
                      ? const Color(0x332A7B6F)
                      : const Color(0x332F2A45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: decoded
                        ? const Color(0xFF6AF0D4)
                        : const Color(0xFF7D7199),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        decoded ? ruin.name : '未解読の${ruin.name}',
                        style: style.copyWith(
                          fontSize: 13,
                          color: decoded
                              ? const Color(0xFF6AF0D4)
                              : const Color(0xFFD1C8E5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        maskedInscription(ruin, decoded: decoded),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '閉じる',
              style: style.copyWith(
                fontSize: 12,
                color: const Color(0xFFD1C8E5),
                shadows: const [],
              ),
            ),
          ),
        ],
      );
    },
  );
}
