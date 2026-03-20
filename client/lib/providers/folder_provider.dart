import 'package:flutter/material.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/database/repositories/folder_repository.dart';
import 'package:synapse/database/repositories/note_repository.dart';

class FolderProvider extends ChangeNotifier {
  final FolderRepository _folderRepo = FolderRepository();
  final NoteRepository _noteRepo = NoteRepository();
  
  List<Folder> _rootFolders = [];
  Folder? _currentFolder;
  List<Folder> _currentSubfolders = [];
  List<Note> _currentNotes = [];
  List<Note> _rootNotes = [];
  bool _isLoading = false;

  List<Folder> get rootFolders => _rootFolders;
  Folder? get currentFolder => _currentFolder;
  List<Folder> get currentSubfolders => _currentSubfolders;
  List<Note> get currentNotes => _currentNotes;
  List<Note> get rootNotes => _rootNotes;
  bool get isLoading => _isLoading;
  bool get isInRoot => _currentFolder == null;

  Future<void> loadRootFolders(int userId) async {
    _isLoading = true;
    notifyListeners();
    
    _rootFolders = await _folderRepo.getRootFolders(userId);
    _rootNotes = await _noteRepo.getNotesWithoutFolder(userId);
    
    // Загружаем подпапки для каждого корневого элемента
    for (var i = 0; i < _rootFolders.length; i++) {
      final subfolders = await _folderRepo.getSubfolders(userId, _rootFolders[i].id!);
      _rootFolders[i] = _rootFolders[i].copyWith(subfolders: subfolders);
    }
    
    _isLoading = false;
    notifyListeners();
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
    _isLoading = true;
    notifyListeners();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final folder = Folder(
      userId: userId,
      parentId: parentFolderId ?? _currentFolder?.id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await _folderRepo.createFolder(folder);
    
    if (id > 0) {
      if (parentFolderId != null) {
        // Если создаем в конкретной папке, обновляем её подпапки
        await _refreshFolderContent(parentFolderId, userId);
      } else if (_currentFolder == null) {
        await loadRootFolders(userId);
      } else {
        _currentSubfolders = await _folderRepo.getSubfolders(userId, _currentFolder!.id!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> createNote(String title, int userId, {int? folderId}) async {
    _isLoading = true;
    notifyListeners();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      userId: userId,
      folderId: folderId ?? _currentFolder?.id,
      title: title,
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await _noteRepo.createNote(note);
    
    if (id > 0) {
      if (folderId != null) {
        // Если создаем в конкретной папке, обновляем её заметки
        await _refreshFolderContent(folderId, userId);
      } else if (_currentFolder != null) {
        _currentNotes = await _folderRepo.getNotesInFolder(userId, _currentFolder!.id!);
      } else {
        _rootNotes = await _noteRepo.getNotesWithoutFolder(userId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateNote(Note note) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _noteRepo.updateNote(note);
    
    if (result > 0) {
      if (note.folderId != null) {
        await _refreshFolderContent(note.folderId!, note.userId);
      } else if (_currentFolder != null) {
        _currentNotes = await _folderRepo.getNotesInFolder(_currentFolder!.userId, _currentFolder!.id!);
      } else {
        _rootNotes = await _noteRepo.getNotesWithoutFolder(note.userId);
      }
    }
    
    _isLoading = false;
    notifyListeners();
    return result > 0;
  }

  Future<bool> deleteNote(int noteId, int userId) async {
    _isLoading = true;
    notifyListeners();
    
    // Сначала получаем заметку чтобы знать её folderId
    final note = await _noteRepo.getNoteById(noteId, userId);
    final folderId = note?.folderId;
    
    final result = await _noteRepo.deleteNote(noteId, userId);
    
    if (result > 0) {
      if (folderId != null) {
        await _refreshFolderContent(folderId, userId);
      } else if (_currentFolder != null) {
        _currentNotes = await _folderRepo.getNotesInFolder(userId, _currentFolder!.id!);
      } else {
        _rootNotes = await _noteRepo.getNotesWithoutFolder(userId);
      }
    }
    
    _isLoading = false;
    notifyListeners();
    return result > 0;
  }

  Future<bool> deleteFolder(Folder folder, int userId) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _folderRepo.deleteFolder(folder.id!, userId);
    
    if (result > 0) {
      if (folder.parentId != null) {
        await _refreshFolderContent(folder.parentId!, userId);
      } else if (_currentFolder?.id == folder.id) {
        goBack();
        await loadRootFolders(userId);
      } else if (_currentFolder == null) {
        await loadRootFolders(userId);
      } else {
        _currentSubfolders = await _folderRepo.getSubfolders(userId, _currentFolder!.id!);
      }
    }
    
    _isLoading = false;
    notifyListeners();
    return result > 0;
  }

  Future<void> _refreshFolderContent(int folderId, int userId) async {
    // Обновляем подпапки и заметки конкретной папки
    final updatedSubfolders = await _folderRepo.getSubfolders(userId, folderId);
    final updatedNotes = await _folderRepo.getNotesInFolder(userId, folderId);
    
    if (_currentFolder?.id == folderId) {
      _currentSubfolders = updatedSubfolders;
      _currentNotes = updatedNotes;
    }
    
    // Обновляем в корневом дереве
    await _updateFolderInTree(_rootFolders, folderId, updatedSubfolders, updatedNotes);
  }

  Future<void> _updateFolderInTree(List<Folder> folders, int folderId, List<Folder> subfolders, List<Note> notes) async {
    for (var i = 0; i < folders.length; i++) {
      if (folders[i].id == folderId) {
        folders[i] = folders[i].copyWith(
          subfolders: subfolders,
        );
        break;
      }
      if (folders[i].subfolders != null && folders[i].subfolders!.isNotEmpty) {
        await _updateFolderInTree(folders[i].subfolders!, folderId, subfolders, notes);
      }
    }
  }

  void clear() {
    _rootFolders = [];
    _rootNotes = [];
    _currentFolder = null;
    _currentSubfolders = [];
    _currentNotes = [];
    notifyListeners();
  }
}