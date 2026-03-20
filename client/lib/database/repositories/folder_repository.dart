import 'package:synapse/database/database_helper.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Получить корневые папки
  Future<List<Folder>> getRootFolders(int userId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'user_id = ? AND parent_id IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    
    List<Folder> folders = [];
    for (var map in maps) {
      folders.add(Folder.fromMap(map));
    }
    return folders;
  }

  // Получить подпапки
  Future<List<Folder>> getSubfolders(int userId, int parentId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'user_id = ? AND parent_id = ?',
      whereArgs: [userId, parentId],
      orderBy: 'created_at ASC',
    );
    
    List<Folder> folders = [];
    for (var map in maps) {
      folders.add(Folder.fromMap(map));
    }
    return folders;
  }

  // Получить заметки в папке
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

  // Создать папку
  Future<int> createFolder(Folder folder) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final folderWithTime = folder.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    
    return await db.insert('folders', folderWithTime.toMap());
  }

  // Обновить папку
  Future<int> updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final updatedFolder = folder.copyWith(updatedAt: now);
    
    return await db.update(
      'folders',
      updatedFolder.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [folder.id, folder.userId],
    );
  }

  // Удалить папку (каскадно удалит все подпапки и заметки)
  Future<int> deleteFolder(int id, int userId) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'folders',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}