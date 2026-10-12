import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[100],
      // استخدام الكلاس الصحيح CardTheme بدلاً من CardThemeData
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
