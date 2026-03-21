import 'package:sqflite/sqflite.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Folder>> getRootFolders(int userId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'user_id = ? AND parent_id IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((map) => Folder.fromMap(map)).toList();
  }

  Future<List<Folder>> getSubfolders(int userId, int parentId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'user_id = ? AND parent_id = ?',
      whereArgs: [userId, parentId],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((map) => Folder.fromMap(map)).toList();
  }

  Future<List<Note>> getNotesInFolder(int userId, int folderId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'user_id = ? AND folder_id = ?',
      whereArgs: [userId, folderId],
      orderBy: 'updated_at DESC',
    );
    
    List<Note> notes = [];
    for (var map in maps) {
      notes.add(Note.fromMap(map));
    }
    return notes;
  }

  Future<int> createFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [folder.id, folder.userId],
    );
  }

  Future<int> deleteFolder(int id, int userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'folders',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<Folder>> getAllFolders(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => Folder.fromMap(map)).toList();
  }
}