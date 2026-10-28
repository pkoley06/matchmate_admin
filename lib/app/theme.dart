import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D28D9)),
    visualDensity: VisualDensity.standard,
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D28D9),
      brightness: Brightness.dark,
    ),
    visualDensity: VisualDensity.standard,
  );
}
