import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synapse/database/models/user_model.dart';
import 'package:synapse/database/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  User? _currentUser;
  bool _isLoading = true;
  bool _isLoggingIn = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggingIn => _isLoggingIn;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        final Map<String, dynamic> map = jsonDecode(userData);
        _currentUser = User.fromMap(map);
        print('👤 Загружен пользователь: ${_currentUser?.username}');
      }
    } catch (e) {
      print('❌ Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoggingIn = true;
    notifyListeners();
    
    try {
      final user = await _userRepo.login(username, password);
      
      if (user != null) {
        _currentUser = user;
        await _saveUser(user);
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoggingIn = true;
    notifyListeners();
    
    try {
      final user = await _userRepo.register(username, email, password);
      
      if (user != null) {
        _currentUser = user;
        await _saveUser(user);
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toMap()));
  }
}