import 'package:sqflite/sqflite.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/database/models/note_model.dart';

class NoteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Note>> getAllNotes(int userId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> notesMaps = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    
    List<Note> notes = [];
    
    for (var noteMap in notesMaps) {
      final note = Note.fromMap(noteMap);
      
      final List<Map<String, dynamic>> tagMaps = await db.rawQuery('''
        SELECT t.name FROM tags t
        INNER JOIN note_tags nt ON t.id = nt.tag_id
        WHERE nt.note_id = ? AND t.user_id = ?
      ''', [note.id, userId]);
      
      note.tags = tagMaps.map((tag) => tag['name'] as String).toList();
      notes.add(note);
    }
    
    return notes;
  }

  Future<Note?> getNoteById(int id, int userId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    
    if (maps.isEmpty) return null;
    
    final note = Note.fromMap(maps.first);
    
    final List<Map<String, dynamic>> tagMaps = await db.rawQuery('''
      SELECT t.name FROM tags t
      INNER JOIN note_tags nt ON t.id = nt.tag_id
      WHERE nt.note_id = ? AND t.user_id = ?
    ''', [id, userId]);
    
    note.tags = tagMaps.map((tag) => tag['name'] as String).toList();
    
    return note;
  }

  Future<int> createNote(Note note) async {
    final db = await _dbHelper.database;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteWithTime = note.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await db.insert('notes', noteWithTime.toMap());
    
    if (note.tags != null && note.tags!.isNotEmpty) {
      await _addTagsToNote(db, id, note.userId, note.tags!);
    }
    
    return id;
  }

  Future<int> updateNote(Note note) async {
    final db = await _dbHelper.database;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedNote = note.copyWith(updatedAt: now);
    
    final result = await db.update(
      'notes',
      updatedNote.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [note.id, note.userId],
    );
    
    if (note.tags != null) {
      await db.delete(
        'note_tags',
        where: 'note_id = ?',
        whereArgs: [note.id],
      );
      
      if (note.tags!.isNotEmpty) {
        await _addTagsToNote(db, note.id!, note.userId, note.tags!);
      }
    }
    
    return result;
  }

  Future<int> deleteNote(int id, int userId) async {
    final db = await _dbHelper.database;
    
    await db.delete(
      'note_tags',
      where: 'note_id = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'notes',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
  
  Future<void> _addTagsToNote(Database db, int noteId, int userId, List<String> tagNames) async {
    for (String tagName in tagNames) {
      List<Map<String, dynamic>> tagMaps = await db.query(
        'tags',
        where: 'name = ? AND user_id = ?',
        whereArgs: [tagName, userId],
      );
      
      int tagId;
      if (tagMaps.isEmpty) {
        tagId = await db.insert('tags', {
          'user_id': userId,
          'name': tagName,
          'color': '#8B7EF6',
        });
      } else {
        tagId = tagMaps.first['id'];
      }
      
      await db.insert('note_tags', {
        'note_id': noteId,
        'tag_id': tagId,
      });
    }
  }
}