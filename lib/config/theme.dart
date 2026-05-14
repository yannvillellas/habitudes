import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light({ColorScheme? colorScheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
    );
  }

  static ThemeData dark({ColorScheme? colorScheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
    );
  }
}
