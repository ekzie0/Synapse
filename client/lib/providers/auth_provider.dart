import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synapse/database/models/user_model.dart';
import 'package:synapse/database/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  User? _currentUser;
  bool _isLoading = true;
  bool _isLoggingIn = false;
  String? _errorMessage; // Фиксация ошибок для вывода на экран

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggingIn => _isLoggingIn;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUser();
  }

  // Утилита хэширования SHA-256
  String _hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Загрузка пользователя при старте с защитой от сломанного кэша
  Future<void> _loadUser() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null && userData.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(userData);
        final loadedUser = User.fromMap(map);

        // Проверяем, существует ли этот пользователь в реальной БД SQLite
        // Если пароли или структура не совпадают, это предотвратит баг "Пользователь не найден"
        final userInDb = await _userRepo.login(loadedUser.username ?? '', loadedUser.password ?? '');
        
        if (userInDb != null) {
          _currentUser = loadedUser;
        } else {
          // Если в БД пользователя с такими данными нет — чистим битый кэш
          await prefs.remove('user_data');
          _currentUser = null;
        }
      }
    } catch (e) {
      print('❌ Ошибка автологина (кэш сброшен): $e');
      _errorMessage = e.toString();
      await forceClearCache(); // Аварийный сброс
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = "Поля не могут быть пустыми";
      notifyListeners();
      return false;
    }

    _isLoggingIn = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final hashedPassword = _hashPassword(password);
      final user = await _userRepo.login(username, hashedPassword);
      
      if (user != null) {
        _currentUser = user;
        await _saveUser(user);
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = "Неверный логин или пароль";
      return false;
    } catch (e) {
      _errorMessage = "Ошибка базы данных при входе";
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    if (username.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = "Заполните все поля";
      notifyListeners();
      return false;
    }

    _isLoggingIn = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final hashedPassword = _hashPassword(password);
      final user = await _userRepo.register(username, email, hashedPassword);
      
      if (user != null) {
        _currentUser = user;
        await _saveUser(user);
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = "Пользователь с таким именем уже существует";
      return false;
    } catch (e) {
      _errorMessage = "Ошибка регистрации";
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(String? avatarPath) async {
    if (_currentUser != null && _currentUser!.id != null) {
      try {
        await _userRepo.updateAvatar(_currentUser!.id!, avatarPath);
        _currentUser = _currentUser!.copyWith(avatarPath: avatarPath);
        await _saveUser(_currentUser!);
        notifyListeners();
      } catch (e) {
        print('❌ Ошибка обновления аватара: $e');
      }
    }
  }

  Future<void> logout() async {
    try {
      _currentUser = null;
      _errorMessage = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      print('❌ Ошибка выхода: $e');
    } finally {
      notifyListeners(); // Гарантированный редирект на экран логина
    }
  }

  // Аварийный метод жесткого сброса, если приложение "залипло"
  Future<void> forceClearCache() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toMap()));
    } catch (e) {
      print('❌ Ошибка сохранения кэша: $e');
    }
  }
}