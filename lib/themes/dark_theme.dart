import 'package:flutter/material.dart';

import '../app_config.dart';

class DarkTheme {
  const DarkTheme._();

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConfig.primaryColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF79C8CA),
      secondary: const Color(0xFFF3B86B),
      surface: const Color(0xFF182022),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF101617),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF182022),
        foregroundColor: Color(0xFFF1F5F4),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFF202A2C),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF182022),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
