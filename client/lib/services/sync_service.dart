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
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/repositories/note_repository.dart';
import 'package:synapse/database/repositories/folder_repository.dart';
import 'dart:developer' as developer; // Твой импорт логов уже на месте!

class SyncService {
  static const int _port = 8080;
  static const String _serviceType = '_synapse._tcp'; 
  static const String _logName = 'WIFI_SYNC'; // Тэг для фильтрации в консоли
  
  HttpServer? _server;
  Registration? _registration; 
  Discovery? _discovery;       
  
  final List<IOWebSocketChannel> _clients = [];
  final Set<String> _syncedDevices = {};
  bool _isRunning = false;
  
  final NoteRepository _noteRepo = NoteRepository();
  final FolderRepository _folderRepo = FolderRepository(); 
  
  Future<void> startAutoSync(int userId) async {
    if (_isRunning) return;
    _isRunning = true;
    
    developer.log('Запуск службы автосинхронизации для пользователя ID: $userId...', name: _logName);
    await _startServer(userId);
    await _startMdns(userId);
  }
  
  Future<void> stopAutoSync() async {
    if (!_isRunning) return;
    _isRunning = false; 
    
    developer.log('Остановка службы автосинхронизации...', name: _logName);
    
    try {
      if (_discovery != null) {
        await stopDiscovery(_discovery!);
        _discovery = null;
        developer.log('mDNS Discovery успешно остановлен.', name: _logName);
      }
    } catch (e) {
      developer.log('Ошибка остановки discovery', name: _logName, error: e);
    }

    try {
      if (_registration != null) {
        await unregister(_registration!);
        _registration = null;
        developer.log('Регистрация mDNS сервиса отменена.', name: _logName);
      }
    } catch (e) {
      developer.log('Ошибка отмены регистрации mDNS', name: _logName, error: e);
    }
    
    _syncedDevices.clear();
    await _stopServer();
    developer.log('Служба автосинхронизации полностью остановлена.', name: _logName);
  }
  
  Future<void> _startServer(int userId) async {
    final ip = await _getLocalIp();
    if (ip == null) {
      developer.log('Не удалось получить локальный IP. Wi-Fi выключен?', name: _logName, level: 900);
      _isRunning = false;
      return;
    }
    
    try {
      _server = await HttpServer.bind(InternetAddress(ip), _port, shared: true);
      developer.log('WebSocket сервер успешно поднят на ws://$ip:$_port/ws', name: _logName);
      
      _server!.listen((HttpRequest request) async {
        if (!_isRunning) return; 
        
        if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
          final WebSocket webSocket = await WebSocketTransformer.upgrade(request);
          final channel = IOWebSocketChannel(webSocket);
          _clients.add(channel);
          
          developer.log('Новое входящее подключение клиента. Всего клиентов: ${_clients.length}', name: _logName);
          
          channel.stream.listen((data) {
            if (_isRunning) _handleData(data, userId, channel);
          }, onDone: () {
            _clients.remove(channel);
            developer.log('Клиент закрыл соединение. Осталось клиентов: ${_clients.length}', name: _logName);
          }, onError: (e) {
            _clients.remove(channel);
            developer.log('Ошибка на стриме клиента', name: _logName, error: e);
          });
        }
      }, onError: (e) => developer.log('Ошибка HttpServer', name: _logName, error: e));
    } catch (e) {
      developer.log('Не удалось запустить HttpServer на порту $_port', name: _logName, error: e);
      _isRunning = false;
    }
  }
  
  Future<void> _startMdns(int userId) async {
    try {
      developer.log('Регистрация mDNS сервиса "$_serviceType"...', name: _logName);
      _registration = await register(const Service(
        name: 'Synapse-Device',
        type: _serviceType,
        port: _port,
      ));
      developer.log('Устройство опубликовано в локальной сети через mDNS.', name: _logName);

      developer.log('Запуск mDNS Discovery поиска других устройств...', name: _logName);
      _discovery = await startDiscovery(_serviceType);
      _discovery!.addListener(() {
        if (!_isRunning) return; 

        for (var service in _discovery!.services) {
          final ip = service.addresses?.isNotEmpty == true ? service.addresses!.first.address : null;
          final port = service.port;
          
          if (ip != null && port != null) {
            final id = '$ip:$port';
            if (!_syncedDevices.contains(id)) {
              developer.log('Обнаружено новое устройство Synapse в сети: $id. Начинаем синхронизацию...', name: _logName);
              _syncedDevices.add(id);
              _connectAndSync(ip, port, userId);
            }
          }
        }
      });
    } catch (e) {
      developer.log('Ошибка инициализации mDNS', name: _logName, error: e);
      _isRunning = false;
    }
  }
  
  Future<void> _connectAndSync(String ip, int port, int userId) async {
    if (!_isRunning) return;
    
    final targetUrl = 'ws://$ip:$port/ws';
    try {
      developer.log('Подключаемся к удаленному серверу: $targetUrl', name: _logName);
      final channel = IOWebSocketChannel.connect(Uri.parse(targetUrl));
      
      final notes = await _noteRepo.getAllNotes(userId);
      final folders = await _folderRepo.getRootFolders(userId); 
      
      developer.log('Отправляем свои данные на $ip (Папок: ${folders.length}, Заметок: ${notes.length})', name: _logName);
      
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
          developer.log('Получен ответный пакет данных от $ip. Начинаем слияние...', name: _logName);
          
          if (data['folders'] != null) {
            await _mergeFolders(data['folders'], userId);
          }
          await _mergeNotes(data['notes'], userId);
          
          developer.log('Синхронизация с $ip успешно завершена!', name: _logName);
          _onSync?.call();
        }
        await channel.sink.close();
      }, onError: (e) {
        developer.log('Ошибка при обмене данными с $ip', name: _logName, error: e);
        channel.sink.close();
      }, onDone: () {
        developer.log('Соединение с $ip закрыто.', name: _logName);
        channel.sink.close();
      });
    } catch (e) {
      developer.log('Не удалось подключиться или синхронизироваться с $targetUrl', name: _logName, error: e);
    }
  }
  
  Future<void> _handleData(dynamic data, int userId, IOWebSocketChannel channel) async {
    if (!_isRunning) return;
    try {
      final json = jsonDecode(data);
      if (json['type'] == 'sync') {
        developer.log('Сервер принял пакет синхронизации от подключенного клиента.', name: _logName);
        
        if (json['folders'] != null) {
          await _mergeFolders(json['folders'], userId);
        }
        await _mergeNotes(json['notes'], userId);
        
        final myNotes = await _noteRepo.getAllNotes(userId);
        final myFolders = await _folderRepo.getRootFolders(userId);
        
        developer.log('Сервер отправляет клиенту ответные локальные данные (Папок: ${myFolders.length}, Заметок: ${myNotes.length})', name: _logName);
        
        channel.sink.add(jsonEncode({
          'type': 'sync', 
          'notes': _notesToJson(myNotes),
          'folders': _foldersToJson(myFolders)
        }));
        
        developer.log('Серверная часть обработки синхронизации завершена.', name: _logName);
        _onSync?.call();
      }
    } catch (e) {
      developer.log('Ошибка сервера при парсинге входящего JSON пакета', name: _logName, error: e);
    }
  }
  
  Future<void> _mergeFolders(List<dynamic> foldersData, int userId) async {
    developer.log('Слияние папок: обрабатывается ${foldersData.length} папок из сети...', name: _logName);
    final localFolders = await _folderRepo.getRootFolders(userId);
    final map = {for (var f in localFolders) f.id: f};

    int createdCount = 0;
    int updatedCount = 0;

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
        createdCount++;
      } else if (folder.updatedAt > existing.updatedAt) {
        try {
          await _folderRepo.updateFolder(folder);
          updatedCount++;
        } catch (e) {
          developer.log('Ошибка вызова updateFolder для папки "${folder.name}"', name: _logName, error: e);
        }
      }
    }
    developer.log('Итог слияния папок: Создано: $createdCount, Обновлено: $updatedCount', name: _logName);
  }
  
  Future<void> _mergeNotes(List<dynamic> notesData, int userId) async {
    developer.log('Слияние заметок: обрабатывается ${notesData.length} заметок из сети...', name: _logName);
    final local = await _noteRepo.getAllNotes(userId);
    final map = {for (var n in local) n.id: n};
    final LinkRepository _linkRepo = LinkRepository();
    
    int createdCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;

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
        createdCount++;
      } else if (note.updatedAt > existing.updatedAt) {
        await _noteRepo.updateNote(note);
        updatedCount++;
      } else {
        skippedCount++;
      }
    }
    developer.log('Итог слияния заметок: Создано: $createdCount, Обновлено: $updatedCount, Пропущено: $skippedCount', name: _logName);

    await Future.delayed(const Duration(milliseconds: 300));
    developer.log('Пересчет Wiki-ссылок и графа связей для обновленных заметок...', name: _logName);

    final allNotesAfterMerge = await _noteRepo.getAllNotes(userId);

    for (var n in notesData) {
      final localNote = allNotesAfterMerge.firstWhere(
        (element) => element.id == n['id'] || element.title.trim().toLowerCase() == n['title'].toString().trim().toLowerCase(),
        orElse: () => Note(userId: userId, title: '', createdAt: 0, updatedAt: 0),
      );

      if (localNote.id != null) {
        try {
          await _linkRepo.updateLinksForNote(localNote, allNotesAfterMerge);
        } catch (e) {
          developer.log('Не удалось обновить связи для заметки ID ${localNote.id}', name: _logName, error: e);
        }
      }
    }
    developer.log('Граф связей успешно обновлен.', name: _logName);
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
        developer.log('HTTP/WebSocket сервер принудительно закрыт.', name: _logName);
      } catch (e) {
        developer.log('Ошибка закрытия сервера', name: _logName, error: e);
      }
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
      final ip = await NetworkInfo().getWifiIP();
      developer.log('Успешно получен локальный Wi-Fi IP: $ip', name: _logName);
      return ip;
    } catch (e) {
      developer.log('Ошибка при получении Wi-Fi IP', name: _logName, error: e);
      return null;
    }
  }
  
  VoidCallback? _onSync;
  void setOnSyncComplete(VoidCallback callback) => _onSync = callback;
}