import 'package:sqflite/sqflite.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/database/models/link_model.dart';
import 'package:synapse/database/models/note_model.dart';

class LinkRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Парсинг ссылок из текста
  List<String> parseLinksFromContent(String content) {
    final RegExp linkRegex = RegExp(r'\[\[(.*?)\]\]');
    final matches = linkRegex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  // Обновить связи для заметки
  Future<void> updateLinksForNote(Note note, List<Note> allNotes) async {
    final db = await _dbHelper.database;
    
    // Удаляем старые связи
    await db.delete(
      'note_links',
      where: 'source_note_id = ?',
      whereArgs: [note.id],
    );
    
    // Парсим новые ссылки
    final linkTitles = parseLinksFromContent(note.content ?? '');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (var title in linkTitles) {
      // Ищем заметку по названию
      final targetNote = allNotes.firstWhere(
        (n) => n.title == title,
        orElse: () => Note(userId: 0, title: '', createdAt: 0, updatedAt: 0),
      );
      
      if (targetNote.id != null) {
        await db.insert('note_links', {
          'source_note_id': note.id,
          'target_note_id': targetNote.id,
          'created_at': now,
        });
      }
    }
  }

  // Получить все связи для заметки
  Future<List<LinkModel>> getLinksForNote(int noteId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'note_links',
      where: 'source_note_id = ? OR target_note_id = ?',
      whereArgs: [noteId, noteId],
    );
    
    return maps.map((map) => LinkModel.fromMap(map)).toList();
  }

  // Получить все связи для графа
  Future<List<LinkModel>> getAllLinks(int userId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT nl.* FROM note_links nl
      INNER JOIN notes n1 ON nl.source_note_id = n1.id
      INNER JOIN notes n2 ON nl.target_note_id = n2.id
      WHERE n1.user_id = ? AND n2.user_id = ?
    ''', [userId, userId]);
    
    return maps.map((map) => LinkModel.fromMap(map)).toList();
  }

  // Получить все заметки с их связями для графа
  Future<Map<int, List<int>>> getGraphData(int userId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT nl.source_note_id, nl.target_note_id FROM note_links nl
      INNER JOIN notes n1 ON nl.source_note_id = n1.id
      INNER JOIN notes n2 ON nl.target_note_id = n2.id
      WHERE n1.user_id = ? AND n2.user_id = ?
    ''', [userId, userId]);
    
    final Map<int, List<int>> graph = {};
    for (var map in maps) {
      final source = map['source_note_id'] as int;
      final target = map['target_note_id'] as int;
      
      graph.putIfAbsent(source, () => []).add(target);
      graph.putIfAbsent(target, () => []).add(source);
    }
    
    return graph;
  }
}