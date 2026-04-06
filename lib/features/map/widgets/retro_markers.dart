import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double _retroMarkerTopSize = 30;
const double _retroPlayerMarkerTopSize = 28;
const double _retroMarkerStemWidth = 4;
const double _retroMarkerStemHeight = 10;
const double _retroMarkerShadowBlur = 4;
const double _retroMarkerShadowYOffset = 2;

Widget _retroMarkerStem({required Color color}) {
  return Container(
    width: _retroMarkerStemWidth,
    height: _retroMarkerStemHeight,
    color: color,
  );
}

BoxShadow _retroMarkerShadow() {
  return const BoxShadow(
    color: Color(0x55000000),
    blurRadius: _retroMarkerShadowBlur,
    offset: Offset(0, _retroMarkerShadowYOffset),
  );
}

class RetroPlayerMarker extends StatelessWidget {
  const RetroPlayerMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _retroPlayerMarkerTopSize,
          height: _retroPlayerMarkerTopSize,
          decoration: BoxDecoration(
            color: const Color(0xFF35D3C7),
            border: Border.all(color: const Color(0xFFFFE088), width: 2),
            boxShadow: [_retroMarkerShadow()],
          ),
          child: const Icon(
            Icons.person,
            size: 18,
            color: Color(0xFF1A1330),
          ),
        ),
        _retroMarkerStem(color: const Color(0xFFFFE088)),
      ],
    );
  }
}

class RetroMemoMarker extends StatelessWidget {
  const RetroMemoMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _retroMarkerTopSize,
          height: _retroMarkerTopSize,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4C2),
            border: Border.all(color: const Color(0xFF3A2F5A), width: 2),
            boxShadow: [_retroMarkerShadow()],
          ),
          child: const Icon(
            Icons.sticky_note_2,
            size: 18,
            color: Color(0xFF4E3A72),
          ),
        ),
        _retroMarkerStem(color: const Color(0xFF3A2F5A)),
      ],
    );
  }
}

class RetroFavoriteMarker extends StatelessWidget {
  const RetroFavoriteMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _retroMarkerTopSize,
          height: _retroMarkerTopSize,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD66B),
            border: Border.all(color: const Color(0xFF3A2F5A), width: 2),
            boxShadow: [_retroMarkerShadow()],
          ),
          child: const Icon(
            Icons.star_rounded,
            size: 20,
            color: Color(0xFF7A4B00),
          ),
        ),
        _retroMarkerStem(color: const Color(0xFF3A2F5A)),
      ],
    );
  }
}

class RetroMemoClusterMarker extends StatelessWidget {
  const RetroMemoClusterMarker({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2E5672),
            border: Border.all(color: const Color(0xFFFFE088), width: 2),
            boxShadow: [_retroMarkerShadow()],
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.dotGothic16(
                textStyle: const TextStyle(
                  color: Color(0xFFFDF8E8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        _retroMarkerStem(color: const Color(0xFFFFE088)),
      ],
    );
  }
}

class RetroRuinMarker extends StatelessWidget {
  const RetroRuinMarker({
    super.key,
    required this.decoded,
  });

  final bool decoded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _retroMarkerTopSize,
          height: _retroMarkerTopSize,
          decoration: BoxDecoration(
            color: decoded ? const Color(0xFF6AF0D4) : const Color(0xFFB6A6D7),
            border: Border.all(color: const Color(0xFF3A2F5A), width: 2),
            boxShadow: [_retroMarkerShadow()],
          ),
          child: Icon(
            decoded ? Icons.account_balance : Icons.help_outline_rounded,
            size: 18,
            color: const Color(0xFF1A1330),
          ),
        ),
        _retroMarkerStem(color: const Color(0xFF3A2F5A)),
      ],
    );
  }
}
