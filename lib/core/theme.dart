import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF00695C),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
