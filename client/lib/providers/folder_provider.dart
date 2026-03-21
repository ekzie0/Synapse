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
  List<Note> _currentNotes = [];
  List<Note> _rootNotes = [];
  List<Note> _allNotes = [];
  
  bool _isLoading = false;

  List<Folder> get rootFolders => _rootFolders;
  Folder? get currentFolder => _currentFolder;
  List<Folder> get currentSubfolders => _currentSubfolders;
  List<Note> get currentNotes => _currentNotes;
  List<Note> get rootNotes => _rootNotes;
  List<Note> get allNotes => _allNotes;
  bool get isLoading => _isLoading;
  bool get isInRoot => _currentFolder == null;

  // Поиск
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

  Future<void> loadRootFolders(int userId) async {
    _isLoading = true;
    notifyListeners();
    
    _rootFolders = await _folderRepo.getRootFolders(userId);
    _rootNotes = await _noteRepo.getNotesWithoutFolder(userId);
    _allNotes = await _noteRepo.getAllNotes(userId);
    
    print("Загружено заметок для поиска: ${_allNotes.length}");
    
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
    _isLoading = true;
    notifyListeners();
    
    _currentFolder = folder;
    _currentSubfolders = await _folderRepo.getSubfolders(userId, folder.id!);
    _currentNotes = await _folderRepo.getNotesInFolder(userId, folder.id!);
    
    _isLoading = false;
    notifyListeners();
  }

  void goBack() {
    _currentFolder = null;
    _currentSubfolders = [];
    _currentNotes = [];
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
      if (parentFolderId != null) {
        await _refreshFolderContent(parentFolderId, userId);
      } else {
        await loadRootFolders(userId);
      }
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
      
      // Обновляем связи
      await _linkRepo.updateLinksForNote(createdNote, _allNotes);

      if (folderId != null) {
        _currentNotes = await _folderRepo.getNotesInFolder(userId, folderId);
      } else {
        _rootNotes = await _noteRepo.getNotesWithoutFolder(userId);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateNote(Note note) async {
    final result = await _noteRepo.updateNote(note);
    
    if (result > 0) {
      // Обновляем связи
      await _linkRepo.updateLinksForNote(note, _allNotes);
      
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = note;
      }

      if (note.folderId != null) {
        await _refreshFolderContent(note.folderId!, note.userId);
      } else {
        _rootNotes = await _noteRepo.getNotesWithoutFolder(note.userId);
        if (_currentFolder == null) _currentNotes = [];
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteNote(int noteId, int userId) async {
    final note = await _noteRepo.getNoteById(noteId, userId);
    final folderId = note?.folderId;
    
    final result = await _noteRepo.deleteNote(noteId, userId);
    if (result > 0) {
      _allNotes.removeWhere((n) => n.id == noteId);

      if (folderId != null) {
        await _refreshFolderContent(folderId, userId);
      } else {
        _rootNotes = await _noteRepo.getNotesWithoutFolder(userId);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteFolder(Folder folder, int userId) async {
    final result = await _folderRepo.deleteFolder(folder.id!, userId);
    if (result > 0) {
      _allNotes.removeWhere((n) => n.folderId == folder.id);

      if (folder.parentId != null) {
        await _refreshFolderContent(folder.parentId!, userId);
      } else {
        await loadRootFolders(userId);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _refreshFolderContent(int folderId, int userId) async {
    final updatedSubfolders = await _folderRepo.getSubfolders(userId, folderId);
    final updatedNotes = await _folderRepo.getNotesInFolder(userId, folderId);
    
    if (_currentFolder?.id == folderId) {
      _currentSubfolders = updatedSubfolders;
      _currentNotes = updatedNotes;
    }
    await _updateFolderInTree(_rootFolders, folderId, updatedSubfolders);
  }

  Future<void> _updateFolderInTree(List<Folder> folders, int folderId, List<Folder> subfolders) async {
    for (var i = 0; i < folders.length; i++) {
      if (folders[i].id == folderId) {
        folders[i] = folders[i].copyWith(subfolders: subfolders);
        break;
      }
      if (folders[i].subfolders != null && folders[i].subfolders!.isNotEmpty) {
        await _updateFolderInTree(folders[i].subfolders!, folderId, subfolders);
      }
    }
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
    _rootNotes = [];
    _allNotes = [];
    _currentFolder = null;
    _currentSubfolders = [];
    _currentNotes = [];
    notifyListeners();
  }
}