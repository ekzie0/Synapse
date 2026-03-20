import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  final String name;
  final Color primaryColor;
  final Brightness brightness;

  const AppTheme({
    required this.name,
    required this.primaryColor,
    required this.brightness,
  });

  static const List<Color> accentColors = [
    Color(0xFF8B7EF6),
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF4FC3F7),
    Color(0xFFF06292),
    Color(0xFFAED581),
    Color(0xFFFF8A65),
  ];

  static const dark = AppTheme(
    name: 'Темная',
    primaryColor: Color(0xFF8B7EF6),
    brightness: Brightness.dark,
  );

  static const light = AppTheme(
    name: 'Светлая',
    primaryColor: Color(0xFF8B7EF6),
    brightness: Brightness.light,
  );

  static const system = AppTheme(
    name: 'Системная',
    primaryColor: Color(0xFF8B7EF6),
    brightness: Brightness.dark,
  );

  ThemeData toThemeData() {
    // Фиксированные цвета для поверхностей
    final Color surfaceColor = brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    
    final Color backgroundColor = brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    // Создаем colorScheme, но переопределяем surface и background
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(
      surface: surfaceColor,
      background: backgroundColor,
      primary: primaryColor, // акцентный цвет
      secondary: primaryColor,
      tertiary: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      
      textTheme: _getTextTheme(brightness).apply(
        fontFamily: 'SF Pro',
        fontFamilyFallback: const [
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
        ],
      ),
      
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primaryColor,
        barBackgroundColor: surfaceColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryColor,
          textStyle: TextStyle(
            fontFamily: 'SF Pro',
            fontFamilyFallback: const [
              'Segoe UI',
              'Roboto',
              'Helvetica Neue',
              'Arial',
            ],
            color: brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
          ),
        ),
      ),
    );
  }

  TextTheme _getTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return TextTheme(
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ).copyWith(color: baseColor),
      
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ).copyWith(color: baseColor),
      
      bodyLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ).copyWith(color: baseColor),
      
      bodyMedium: const TextStyle(
        fontSize: 13,
      ).copyWith(
        color: brightness == Brightness.dark 
            ? const Color(0xFF9E9E9E)
            : const Color(0xFF757575),
      ),
      
      labelLarge: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ).copyWith(color: baseColor),
    );
  }
}