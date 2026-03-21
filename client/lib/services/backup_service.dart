import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/database/models/tag_model.dart';
import 'package:synapse/database/repositories/folder_repository.dart';
import 'package:synapse/database/repositories/note_repository.dart';
import 'package:synapse/database/repositories/tag_repository.dart';

class BackupService {
  final FolderRepository _folderRepo = FolderRepository();
  final NoteRepository _noteRepo = NoteRepository();
  final TagRepository _tagRepo = TagRepository();

  // Структура для экспорта
  Map<String, dynamic> _buildExportData(
    List<Folder> folders,
    List<Note> notes,
    List<Tag> tags,
  ) {
    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'folders': folders.map((f) => {
        'id': f.id,
        'parent_id': f.parentId,
        'name': f.name,
        'created_at': f.createdAt,
        'updated_at': f.updatedAt,
      }).toList(),
      'notes': notes.map((n) => {
        'id': n.id,
        'folder_id': n.folderId,
        'title': n.title,
        'content': n.content,
        'tags': n.tags,
        'images': n.images,
        'created_at': n.createdAt,
        'updated_at': n.updatedAt,
      }).toList(),
      'tags': tags.map((t) => {
        'id': t.id,
        'name': t.name,
        'color': t.color,
      }).toList(),
    };
  }

  // Экспорт в JSON файл
  Future<String?> exportToJson(int userId) async {
    try {
      final folders = await _folderRepo.getAllFolders(userId);
      final notes = await _noteRepo.getAllNotes(userId);
      final tags = await _tagRepo.getAllTags(userId);
      
      final data = _buildExportData(folders, notes, tags);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'synapse_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      print('Ошибка экспорта: $e');
      return null;
    }
  }

  // Экспорт в Markdown (папка с файлами)
  Future<String?> exportToMarkdown(int userId) async {
    try {
      final notes = await _noteRepo.getAllNotes(userId);
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/synapse_markdown_${DateTime.now().millisecondsSinceEpoch}');
      await exportDir.create();
      
      for (var note in notes) {
        final fileName = '${_sanitizeFileName(note.title)}.md';
        final filePath = '${exportDir.path}/$fileName';
        final content = _noteToMarkdown(note);
        await File(filePath).writeAsString(content);
      }
      
      return exportDir.path;
    } catch (e) {
      print('Ошибка экспорта в Markdown: $e');
      return null;
    }
  }

  String _noteToMarkdown(Note note) {
    final buffer = StringBuffer();
    buffer.writeln('# ${note.title}');
    buffer.writeln();
    buffer.writeln('**Дата создания:** ${DateTime.fromMillisecondsSinceEpoch(note.createdAt)}');
    buffer.writeln('**Последнее изменение:** ${DateTime.fromMillisecondsSinceEpoch(note.updatedAt)}');
    buffer.writeln();
    if (note.tags != null && note.tags!.isNotEmpty) {
      buffer.writeln('**Теги:** ${note.tags!.join(', ')}');
      buffer.writeln();
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(note.content ?? '');
    return buffer.toString();
  }

  String _sanitizeFileName(String name) {
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(invalidChars, '_');
  }

  // Импорт из JSON
  Future<bool> importFromJson(String filePath, int userId) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      // Создаем карты старых ID -> новые ID
      final folderIdMap = <int, int>{};
      final tagIdMap = <int, int>{};
      
      // Импорт тегов
      for (var tagData in data['tags']) {
        final tag = Tag(
          userId: userId,
          name: tagData['name'],
          color: tagData['color'],
        );
        final newId = await _tagRepo.createTag(tag);
        tagIdMap[tagData['id']] = newId;
      }
      
      // Импорт папок (сначала корневые)
      final rootFolders = (data['folders'] as List).where((f) => f['parent_id'] == null).toList();
      final childFolders = (data['folders'] as List).where((f) => f['parent_id'] != null).toList();
      
      for (var folderData in rootFolders) {
        final folder = Folder(
          userId: userId,
          parentId: null,
          name: folderData['name'],
          createdAt: folderData['created_at'],
          updatedAt: folderData['updated_at'],
        );
        final newId = await _folderRepo.createFolder(folder);
        folderIdMap[folderData['id']] = newId;
      }
      
      for (var folderData in childFolders) {
        final oldParentId = folderData['parent_id'];
        final newParentId = folderIdMap[oldParentId];
        if (newParentId != null) {
          final folder = Folder(
            userId: userId,
            parentId: newParentId,
            name: folderData['name'],
            createdAt: folderData['created_at'],
            updatedAt: folderData['updated_at'],
          );
          final newId = await _folderRepo.createFolder(folder);
          folderIdMap[folderData['id']] = newId;
        }
      }
      
      // Импорт заметок
      for (var noteData in data['notes']) {
        final oldFolderId = noteData['folder_id'];
        final newFolderId = oldFolderId != null ? folderIdMap[oldFolderId] : null;
        
        final note = Note(
          userId: userId,
          folderId: newFolderId,
          title: noteData['title'],
          content: noteData['content'],
          createdAt: noteData['created_at'],
          updatedAt: noteData['updated_at'],
          tags: (noteData['tags'] as List?)?.cast<String>(),
          images: (noteData['images'] as List?)?.cast<String>(),
        );
        await _noteRepo.createNote(note);
      }
      
      return true;
    } catch (e) {
      print('Ошибка импорта: $e');
      return false;
    }
  }

  // Импорт из Markdown (папка с .md файлами)
  Future<bool> importFromMarkdown(String folderPath, int userId) async {
    try {
      final directory = Directory(folderPath);
      final files = directory.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));
      
      for (var file in files) {
        final content = await file.readAsString();
        final note = _parseMarkdownToNote(content, userId);
        if (note != null) {
          await _noteRepo.createNote(note);
        }
      }
      
      return true;
    } catch (e) {
      print('Ошибка импорта из Markdown: $e');
      return false;
    }
  }

  Note? _parseMarkdownToNote(String content, int userId) {
    final lines = content.split('\n');
    String? title;
    String? body;
    List<String> tags = [];
    
    for (var line in lines) {
      if (line.startsWith('# ')) {
        title = line.substring(2).trim();
      } else if (line.startsWith('**Теги:**')) {
        final tagsStr = line.replaceAll('**Теги:**', '').trim();
        tags = tagsStr.split(',').map((t) => t.trim()).toList();
      } else if (line.startsWith('---')) {
        // Разделитель, после него идет содержимое
        final startIndex = lines.indexOf(line) + 1;
        body = lines.sublist(startIndex).join('\n').trim();
        break;
      }
    }
    
    if (title == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    return Note(
      userId: userId,
      title: title,
      content: body,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Поделиться файлом
  Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    await Share.shareXFiles([XFile(filePath)], text: 'Резервная копия Synapse');
  }

  // Выбрать файл для импорта
  Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['json'],
      dialogTitle: 'Выберите файл резервной копии',
    );
    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  // Выбрать папку для импорта Markdown
  Future<String?> pickMarkdownFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите папку с Markdown файлами',
    );
    return result;
  }

  // Получить размер резервной копии
  Future<int> getBackupSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}