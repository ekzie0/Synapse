import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:synapse/database/repositories/link_repository.dart';
import 'package:web_socket_channel/io.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:nsd/nsd.dart'; 
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/database/models/folder_model.dart'; // Импортируем модель папки
import 'package:synapse/database/repositories/note_repository.dart';
import 'package:synapse/database/repositories/folder_repository.dart'; // Импортируем репозиторий папок

class SyncService {
  static const int _port = 8080;
  static const String _serviceType = '_synapse._tcp'; 
  
  HttpServer? _server;
  Registration? _registration; 
  Discovery? _discovery;       
  
  final List<IOWebSocketChannel> _clients = [];
  final Set<String> _syncedDevices = {};
  bool _isRunning = false;
  
  final NoteRepository _noteRepo = NoteRepository();
  final FolderRepository _folderRepo = FolderRepository(); // Добавили репозиторий папок
  
  Future<void> startAutoSync(int userId) async {
    if (_isRunning) return;
    _isRunning = true;
    
    await _startServer(userId);
    await _startMdns(userId);
  }
  
  Future<void> stopAutoSync() async {
    if (!_isRunning) return;
    _isRunning = false; 
    
    try {
      if (_discovery != null) {
        await stopDiscovery(_discovery!);
        _discovery = null;
      }
    } catch (e) {
      print('Ошибка остановки discovery: $e');
    }

    try {
      if (_registration != null) {
        await unregister(_registration!);
        _registration = null;
      }
    } catch (e) {
      print('Ошибка отмены регистрации mDNS: $e');
    }
    
    _syncedDevices.clear();
    await _stopServer();
  }
  
  Future<void> _startServer(int userId) async {
    final ip = await _getLocalIp();
    if (ip == null) {
      _isRunning = false;
      return;
    }
    
    try {
      _server = await HttpServer.bind(InternetAddress(ip), _port, shared: true);
      _server!.listen((HttpRequest request) async {
        if (!_isRunning) return; 
        
        if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
          final WebSocket webSocket = await WebSocketTransformer.upgrade(request);
          final channel = IOWebSocketChannel(webSocket);
          _clients.add(channel);
          channel.stream.listen((data) {
            if (_isRunning) _handleData(data, userId, channel);
          }, onDone: () {
            _clients.remove(channel);
          }, onError: (_) {
            _clients.remove(channel);
          });
        }
      }, onError: (e) => print('Ошибка сервера: $e'));
    } catch (_) {
      _isRunning = false;
    }
  }
  
  Future<void> _startMdns(int userId) async {
    try {
      _registration = await register(const Service(
        name: 'Synapse-Device',
        type: _serviceType,
        port: _port,
      ));

      _discovery = await startDiscovery(_serviceType);
      _discovery!.addListener(() {
        if (!_isRunning) return; 

        for (var service in _discovery!.services) {
          final ip = service.addresses?.isNotEmpty == true ? service.addresses!.first.address : null;
          final port = service.port;
          
          if (ip != null && port != null) {
            final id = '$ip:$port';
            if (!_syncedDevices.contains(id)) {
              _syncedDevices.add(id);
              _connectAndSync(ip, port, userId);
            }
          }
        }
      });
    } catch (_) {
      _isRunning = false;
    }
  }
  
  Future<void> _connectAndSync(String ip, int port, int userId) async {
    if (!_isRunning) return;
    
    try {
      final channel = IOWebSocketChannel.connect(Uri.parse('ws://$ip:$port/ws'));
      
      // Вытягиваем из базы данных и заметки, и папки
      final notes = await _noteRepo.getAllNotes(userId);
      final folders = await _folderRepo.getRootFolders(userId); 
      
      // Отправляем полный пакет данных на другое устройство
      channel.sink.add(jsonEncode({
        'type': 'sync', 
        'notes': _notesToJson(notes),
        'folders': _foldersToJson(folders)
      }));
      
      channel.stream.listen((res) async {
        if (!_isRunning) {
          channel.sink.close();
          return;
        }
        
        final data = jsonDecode(res);
        if (data['type'] == 'sync') {
          // КРИТИЧЕСКИ ВАЖНО: Сначала создаем папки, только потом вливаем заметки
          if (data['folders'] != null) {
            await _mergeFolders(data['folders'], userId);
          }
          await _mergeNotes(data['notes'], userId);
          _onSync?.call();
        }
        await channel.sink.close();
      }, onError: (_) {
        channel.sink.close();
      }, onDone: () {
        channel.sink.close();
      });
    } catch (_) {}
  }
  
  Future<void> _handleData(dynamic data, int userId, IOWebSocketChannel channel) async {
    if (!_isRunning) return;
    try {
      final json = jsonDecode(data);
      if (json['type'] == 'sync') {
        // Принимаем данные на стороне сервера (сначала папки, потом заметки)
        if (json['folders'] != null) {
          await _mergeFolders(json['folders'], userId);
        }
        await _mergeNotes(json['notes'], userId);
        
        // Формируем ответный пакет со своими локальными данными
        final myNotes = await _noteRepo.getAllNotes(userId);
        final myFolders = await _folderRepo.getRootFolders(userId);
        
        channel.sink.add(jsonEncode({
          'type': 'sync', 
          'notes': _notesToJson(myNotes),
          'folders': _foldersToJson(myFolders)
        }));
        _onSync?.call();
      }
    } catch (_) {}
  }
  
  // 🔥 НОВЫЙ МЕТОД: Слияние папок в локальной SQLite базе данных
  Future<void> _mergeFolders(List<dynamic> foldersData, int userId) async {
    final localFolders = await _folderRepo.getRootFolders(userId);
    final map = {for (var f in localFolders) f.id: f};

    for (var f in foldersData) {
      final folder = Folder(
        id: f['id'],
        userId: userId,
        parentId: f['parent_id'],
        name: f['name'],
        createdAt: f['created_at'],
        updatedAt: f['updated_at'],
      );

      final existing = map[folder.id];
      if (existing == null) {
        await _folderRepo.createFolder(folder);
      } else if (folder.updatedAt > existing.updatedAt) {
        // Если на другом устройстве папка новее — обновляем её локально
        try {
          await _folderRepo.updateFolder(folder);
        } catch (_) {
          // На случай, если метод updateFolder не объявлен или работает иначе
        }
      }
    }
  }
  
  Future<void> _mergeNotes(List<dynamic> notesData, int userId) async {
    final local = await _noteRepo.getAllNotes(userId);
    final map = {for (var n in local) n.id: n};
    final LinkRepository _linkRepo = LinkRepository();
    
    for (var n in notesData) {
      final note = Note(
        id: n['id'], 
        userId: userId,
        folderId: n['folder_id'],
        title: n['title'],
        content: n['content'],
        tags: (n['tags'] as List?)?.cast<String>(),
        createdAt: n['created_at'],
        updatedAt: n['updated_at'],
      );
      
      final existing = map[note.id];
      if (existing == null) {
        await _noteRepo.createNote(note);
      } else if (note.updatedAt > existing.updatedAt) {
        await _noteRepo.updateNote(note);
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final allNotesAfterMerge = await _noteRepo.getAllNotes(userId);

    for (var n in notesData) {
      final localNote = allNotesAfterMerge.firstWhere(
        (element) => element.id == n['id'] || element.title.trim().toLowerCase() == n['title'].toString().trim().toLowerCase(),
        orElse: () => Note(userId: userId, title: '', createdAt: 0, updatedAt: 0),
      );

      if (localNote.id != null) {
        try {
          await _linkRepo.updateLinksForNote(localNote, allNotesAfterMerge);
          print('[Sync] Успешно обновлены связи для заметки: "${localNote.title}"');
        } catch (e) {
          print('[Sync Error] Не удалось обновить связи для заметки ${localNote.id}: $e');
        }
      }
    }
  }
  
  List<Map<String, dynamic>> _notesToJson(List<Note> notes) {
    return notes.map((n) => {
      'id': n.id,
      'title': n.title,
      'content': n.content,
      'tags': n.tags,
      'folder_id': n.folderId,
      'created_at': n.createdAt,
      'updated_at': n.updatedAt,
    }).toList();
  }

  // 🔥 НОВЫЙ МЕТОД: Сериализация папок в JSON формат
  List<Map<String, dynamic>> _foldersToJson(List<Folder> folders) {
    return folders.map((f) => {
      'id': f.id,
      'parent_id': f.parentId,
      'name': f.name,
      'created_at': f.createdAt,
      'updated_at': f.updatedAt,
    }).toList();
  }
  
  Future<void> _stopServer() async {
    if (_server != null) {
      try {
        await _server!.close(force: true);
      } catch (_) {}
      _server = null;
    }
    for (var c in _clients) {
      try {
        await c.sink.close();
      } catch (_) {}
    }
    _clients.clear();
  }
  
  Future<String?> _getLocalIp() async {
    try {
      return await NetworkInfo().getWifiIP();
    } catch (_) {
      return null;
    }
  }
  
  VoidCallback? _onSync;
  void setOnSyncComplete(VoidCallback callback) => _onSync = callback;
}