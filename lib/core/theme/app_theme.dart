import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getLight() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    );
  }
}