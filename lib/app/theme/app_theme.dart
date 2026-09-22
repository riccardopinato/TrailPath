import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color forest = Color(0xFF236146);
  static const Color moss = Color(0xFF6D8B5B);
  static const Color sand = Color(0xFFF0E8D7);
  static const Color ink = Color(0xFF17211B);
  static const Color night = Color(0xFF0F1713);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: brightness,
      surface: isDark ? const Color(0xFF151D18) : const Color(0xFFF8FAF7),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? night : const Color(0xFFF3F6F1),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor:
            isDark ? const Color(0xFF151D18) : const Color(0xFFFBFCFA),
        indicatorColor: isDark
            ? const Color(0xFF284B39)
            : const Color(0xFFD8EBDD),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
            headlineMedium: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            titleMedium: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
    );
  }
}
