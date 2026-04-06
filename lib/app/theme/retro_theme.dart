import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef RetroTextStyleBuilder = TextStyle Function({
  required Color color,
  required double fontSize,
  required double height,
});

ThemeData buildRetroTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF4B4457),
    useMaterial3: true,
    textTheme: GoogleFonts.pressStart2pTextTheme(
      ThemeData.dark().textTheme,
    ),
  );
}

TextStyle buildRetroTextStyle({
  required Color color,
  required double fontSize,
  required double height,
}) {
  return GoogleFonts.dotGothic16(
    textStyle: TextStyle(
      color: color,
      fontSize: fontSize,
      height: height,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      shadows: const [
        Shadow(
          offset: Offset(1, 1),
          color: Color(0xFF1A1330),
        ),
        Shadow(
          offset: Offset(-1, 0),
          color: Color(0x991A1330),
        ),
      ],
    ),
  );
}
