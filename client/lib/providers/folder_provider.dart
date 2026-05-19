import 'package:flutter/material.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/database/repositories/folder_repository.dart';
import 'package:synapse/database/repositories/note_repository.dart';
import 'package:synapse/database/repositories/link_repository.dart';

class FolderProvider extends ChangeNotifier {
  final FolderRepository _folderRepo = FolderRepository();
  final NoteRepository _noteRepo = NoteRepository();
  final LinkRepository _linkRepo = LinkRepository();
  
  List<Folder> _rootFolders = [];
  Folder? _currentFolder;
  List<Folder> _currentSubfolders = [];
  List<Note> _allNotes = [];
  bool _isLoading = false;

  List<Folder> get rootFolders => _rootFolders;
  Folder? get currentFolder => _currentFolder;
  List<Folder> get currentSubfolders => _currentSubfolders;
  List<Note> get allNotes => _allNotes;
  
  // Заметки в текущей папке
  List<Note> get currentNotes {
    if (_currentFolder == null) return _allNotes.where((n) => n.folderId == null).toList();
    return _allNotes.where((n) => n.folderId == _currentFolder!.id).toList();
  }
  
  // Заметки в корне
  List<Note> get rootNotes {
    return _allNotes.where((n) => n.folderId == null).toList();
  }
  
  bool get isLoading => _isLoading;
  bool get isInRoot => _currentFolder == null;

  Future<Folder?> getFolderById(int folderId) async {
    return await _folderRepo.getFolderById(folderId);
  }

  // Для обратной совместимости
  Future<void> loadRootFolders(int userId) async {
    await loadAllData(userId);
  }

  List<Note> searchAllNotes(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _allNotes.where((note) {
      if (note.title.toLowerCase().contains(lowerQuery)) return true;
      if (note.content != null && note.content!.toLowerCase().contains(lowerQuery)) return true;
      if (note.tags != null) {
        for (var tag in note.tags!) {
          if (tag.toLowerCase().contains(lowerQuery)) return true;
        }
      }
      return false;
    }).toList();
  }

  Future<void> loadAllData(int userId) async {
    _isLoading = true;
    notifyListeners();
    
    _rootFolders = await _folderRepo.getRootFolders(userId);
    _allNotes = await _noteRepo.getAllNotes(userId);
    
    for (var i = 0; i < _rootFolders.length; i++) {
      final subfolders = await _folderRepo.getSubfolders(userId, _rootFolders[i].id!);
      _rootFolders[i] = _rootFolders[i].copyWith(subfolders: subfolders);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Folder>> getSubfolders(int folderId, int userId) async {
    return await _folderRepo.getSubfolders(userId, folderId);
  }

  Future<void> openFolder(Folder folder, int userId) async {
    _currentFolder = folder;
    _currentSubfolders = await _folderRepo.getSubfolders(userId, folder.id!);
    notifyListeners();
  }

  void goBack() {
    _currentFolder = null;
    _currentSubfolders = [];
    notifyListeners();
  }

  Future<bool> createFolder(String name, int userId, {int? parentFolderId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final folder = Folder(
      userId: userId,
      parentId: parentFolderId,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await _folderRepo.createFolder(folder);
    if (id > 0) {
      await loadAllData(userId);
      return true;
    }
    return false;
  }

  Future<bool> createNote(String title, int userId, {int? folderId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      userId: userId,
      folderId: folderId,
      title: title,
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await _noteRepo.createNote(note);
    if (id > 0) {
      final createdNote = note.copyWith(id: id);
      _allNotes.add(createdNote);
      await _linkRepo.updateLinksForNote(createdNote, _allNotes);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateNote(Note note) async {
    final result = await _noteRepo.updateNote(note);
    if (result > 0) {
      await _linkRepo.updateLinksForNote(note, _allNotes);
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = note;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteNote(int noteId, int userId) async {
    final result = await _noteRepo.deleteNote(noteId, userId);
    if (result > 0) {
      _allNotes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteFolder(Folder folder, int userId) async {
    final result = await _folderRepo.deleteFolder(folder.id!, userId);
    if (result > 0) {
      await loadAllData(userId);
      if (_currentFolder?.id == folder.id) {
        _currentFolder = null;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Note? getNoteByTitle(String title) {
    final cleanSearchTitle = title.trim().toLowerCase();
    try {
      return _allNotes.firstWhere(
        (n) => n.title.trim().toLowerCase() == cleanSearchTitle
      );
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _rootFolders = [];
    _allNotes = [];
    _currentFolder = null;
    _currentSubfolders = [];
    notifyListeners();
  }
}