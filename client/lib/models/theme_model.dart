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

  // Предустановленные цвета
  static const List<Color> accentColors = [
    Color(0xFF8B7EF6), // фиолетовый (дефолтный)
    Color(0xFFE57373), // красный
    Color(0xFF64B5F6), // синий
    Color(0xFF81C784), // зеленый
    Color(0xFFFFB74D), // оранжевый
    Color(0xFFBA68C8), // розовый
    Color(0xFF4FC3F7), // голубой
    Color(0xFFF06292), // розово-красный
    Color(0xFFAED581), // салатовый
    Color(0xFFFF8A65), // коралловый
  ];

  // Базовая темная тема
  static const dark = AppTheme(
    name: 'Темная',
    primaryColor: Color(0xFF8B7EF6),
    brightness: Brightness.dark,
  );

  // Базовая светлая тема
  static const light = AppTheme(
    name: 'Светлая',
    primaryColor: Color(0xFF8B7EF6),
    brightness: Brightness.light,
  );

  // Системная тема
  static const system = AppTheme(
    name: 'Системная',
    primaryColor: Color(0xFF8B7EF6),
    brightness: Brightness.dark, // заглушка
  );

  // Создание ThemeData из модели
  ThemeData toThemeData() {
    // Создаем базовую тему
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(
      surface: brightness == Brightness.dark 
          ? const Color(0xFF1E1E1E) 
          : Colors.white,
      // background больше не используем (deprecated)
    );

    return ThemeData(
      useMaterial3: false,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      
      // 👇 Правильный способ задать шрифт
      textTheme: _getTextTheme(brightness).apply(
        fontFamily: 'SF Pro',
        fontFamilyFallback: const [
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
        ],
      ),
      
      // 👇 Для Cupertino (iOS стиль)
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primaryColor,
        barBackgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
