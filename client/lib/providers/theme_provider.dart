import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  
  AppTheme _currentTheme = AppTheme.dark;
  bool _useSystemTheme = false;
  
  AppTheme get currentTheme => _currentTheme;
  bool get useSystemTheme => _useSystemTheme;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем сохраненную тему
    final savedThemeMode = prefs.getString(_themeModeKey) ?? 'Темная';
    _useSystemTheme = savedThemeMode == 'Системная';
    
    // Загружаем сохраненный цвет
    final savedColor = prefs.getInt(_accentColorKey);
    Color accentColor;
    
    if (savedColor != null) {
      accentColor = Color(savedColor);
      print('Загружен цвет: $accentColor'); // Для отладки
    } else {
      accentColor = const Color(0xFF8B7EF6);
      print('Используем цвет по умолчанию');
    }
    
    if (_useSystemTheme) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _currentTheme = AppTheme(
        name: 'Системная',
        primaryColor: accentColor,
        brightness: brightness,
      );
    } else {
      _currentTheme = AppTheme(
        name: savedThemeMode,
        primaryColor: accentColor,
        brightness: savedThemeMode == 'Темная' ? Brightness.dark : Brightness.light,
      );
    }
    
    print('Текущая тема: ${_currentTheme.name}, цвет: ${_currentTheme.primaryColor}');
    notifyListeners();
  }

  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _currentTheme.name);
    await prefs.setInt(_accentColorKey, _currentTheme.primaryColor.value);
    print('Сохранена тема: ${_currentTheme.name}, цвет: ${_currentTheme.primaryColor.value}');
  }

  Future<void> setThemeMode(String mode) async {
    if (mode == 'system') {
      _useSystemTheme = true;
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _currentTheme = AppTheme(
        name: 'Системная',
        primaryColor: _currentTheme.primaryColor,
        brightness: brightness,
      );
    } else {
      _useSystemTheme = false;
      _currentTheme = AppTheme(
        name: mode,
        primaryColor: _currentTheme.primaryColor,
        brightness: mode == 'Темная' ? Brightness.dark : Brightness.light,
      );
    }
    
    await _saveThemeSettings();
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    print('Устанавливаем новый цвет: $color');
    _currentTheme = AppTheme(
      name: _currentTheme.name,
      primaryColor: color,
      brightness: _currentTheme.brightness,
    );
    
    await _saveThemeSettings();
    notifyListeners();
  }

  void updateSystemTheme(Brightness brightness) {
    if (_useSystemTheme) {
      _currentTheme = AppTheme(
        name: 'Системная',
        primaryColor: _currentTheme.primaryColor,
        brightness: brightness,
      );
      notifyListeners();
    }
  }
}