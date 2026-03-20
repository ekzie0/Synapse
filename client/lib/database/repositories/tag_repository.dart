import 'package:sqflite/sqflite.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/database/models/tag_model.dart';

class TagRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Tag>> getAllTags(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  Future<int> createTag(Tag tag) async {
    final db = await _dbHelper.database;
    return await db.insert('tags', tag.toMap());
  }

  Future<int> deleteTag(int id, int userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'tags',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}