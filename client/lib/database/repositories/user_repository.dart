import 'package:sqflite/sqflite.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/database/models/user_model.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<User?> register(String username, String email, String password) async {
    final db = await _dbHelper.database;
    
    final existingUser = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [username, email],
    );
    
    if (existingUser.isNotEmpty) {
      return null;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final user = User(
      username: username,
      email: email,
      password: password,
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> login(String username, String password) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedUser = user.copyWith(updatedAt: now);
    
    return await db.update(
      'users',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateAvatar(int userId, String? avatarPath) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.update(
      'users',
      {
        'avatar_path': avatarPath,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}