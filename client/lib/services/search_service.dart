import 'package:synapse/database/models/note_model.dart';

class SearchService {
  static List<Note> searchNotes(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    
    final lowerQuery = query.toLowerCase();
    
    return notes.where((note) {
      // Поиск по заголовку
      if (note.title.toLowerCase().contains(lowerQuery)) return true;
      
      // Поиск по содержимому
      if (note.content != null && note.content!.toLowerCase().contains(lowerQuery)) return true;
      
      // Поиск по тегам
      if (note.tags != null) {
        for (var tag in note.tags!) {
          if (tag.toLowerCase().contains(lowerQuery)) return true;
        }
      }
      
      return false;
    }).toList();
  }
}