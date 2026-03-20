import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synapse/database/models/user_model.dart';
import 'package:synapse/database/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    
    if (userData != null) {
      final Map<String, dynamic> map = jsonDecode(userData);
      _currentUser = User.fromMap(map);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    final user = await _userRepo.login(username, password);
    
    _isLoading = false;
    
    if (user != null) {
      _currentUser = user;
      await _saveUser(user);
      notifyListeners();
      return true;
    }
    
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    final user = await _userRepo.register(username, email, password);
    
    _isLoading = false;
    
    if (user != null) {
      _currentUser = user;
      await _saveUser(user);
      notifyListeners();
      return true;
    }
    
    notifyListeners();
    return false;
  }

  Future<void> updateAvatar(String? avatarPath) async {
    if (_currentUser != null) {
      await _userRepo.updateAvatar(_currentUser!.id!, avatarPath);
      
      _currentUser = _currentUser!.copyWith(avatarPath: avatarPath);
      await _saveUser(_currentUser!);
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