import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const MethodChannel _channel = MethodChannel('synapse.go.backend');
  static const String _userKey = 'synapse_user';
  
  // Текущий пользователь
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  // Слушатели изменений
  final List<Function(User?)> _listeners = [];
  
  // Инициализация при запуске
  Future<void> init() async {
    await _loadSavedUser();
  }
  
  // Загружаем сохраненного пользователя
  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
        _notifyListeners();
      }
    } catch (e) {
      print('Ошибка загрузки пользователя: $e');
    }
  }
  
  // Сохраняем пользователя
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    _currentUser = user;
    _notifyListeners();
  }
  
  // Регистрация
  Future<User> register(String email, String password, {String? name}) async {
    try {
      final result = await _channel.invokeMethod('register', {
        'email': email,
        'password': password,
        'name': name,
      });
      
      final user = User.fromJson(json.decode(result));
      await _saveUser(user);
      return user;
    } on PlatformException catch (e) {
      throw Exception('Ошибка регистрации: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
    }
  }
  
  // Вход
  Future<User> login(String email, String password) async {
    try {
      final result = await _channel.invokeMethod('login', {
        'email': email,
        'password': password,
      });
      
      final user = User.fromJson(json.decode(result));
      await _saveUser(user);
      return user;
    } on PlatformException catch (e) {
      throw Exception('Ошибка входа: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }
  
  // Вход как гость
  Future<User> loginAsGuest() async {
    try {
      final result = await _channel.invokeMethod('loginAsGuest');
      final user = User.fromJson(json.decode(result));
      await _saveUser(user);
      return user;
    } on PlatformException catch (e) {
      throw Exception('Ошибка входа как гость: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка входа как гость: $e');
    }
  }
  
  // Выход
  Future<void> logout() async {
    try {
      await _channel.invokeMethod('logout');
    } on PlatformException catch (e) {
      print('Ошибка при выходе: ${e.message}');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUser = null;
    _notifyListeners();
  }
  
  // Подписка на изменения
  void addListener(Function(User?) listener) {
    _listeners.add(listener);
  }
  
  void removeListener(Function(User?) listener) {
    _listeners.remove(listener);
  }
  
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_currentUser);
    }
  }
}

// Синглтон
final authService = AuthService();