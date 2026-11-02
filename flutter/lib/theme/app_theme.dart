import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color background = Color(0xFFF4F7F5);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
  );
}
