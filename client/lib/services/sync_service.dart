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
import 'package:synapse/database/repositories/note_repository.dart';

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
  
  Future<void> startAutoSync(int userId) async {
    if (_isRunning) return;
    _isRunning = true;
    
    await _startServer(userId);
    await _startMdns(userId);
  }
  
  Future<void> stopAutoSync() async {
    if (!_isRunning) return;
    _isRunning = false; // Мгновенно ставим флаг в false
    
    // Безопасно останавливаем mDNS поиск и регистрацию
    try {
      if (_discovery != null) {
        // Правильный вызов остановки discovery в библиотеке nsd
        await stopDiscovery(_discovery!);
        _discovery = null;
      }
    } catch (e) {
      print('Ошибка остановки discovery: $e');
    }

    try {
      if (_registration != null) {
        // Правильный вызов отмены регистрации в библиотеке nsd
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
        if (!_isRunning) return; // Если сервис остановлен, игнорируем запросы
        
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
        if (!_isRunning) return; // Важно: если мы выключили сервис, выходим!

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
      final notes = await _noteRepo.getAllNotes(userId);
      
      channel.sink.add(jsonEncode({'type': 'sync', 'notes': _notesToJson(notes)}));
      
      channel.stream.listen((res) async {
        if (!_isRunning) {
          channel.sink.close();
          return;
        }
        
        final data = jsonDecode(res);
        if (data['type'] == 'sync') {
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
        await _mergeNotes(json['notes'], userId);
        final myNotes = await _noteRepo.getAllNotes(userId);
        channel.sink.add(jsonEncode({'type': 'sync', 'notes': _notesToJson(myNotes)}));
        _onSync?.call();
      }
    } catch (_) {}
  }
  
  Future<void> _mergeNotes(List<dynamic> notesData, int userId) async {
    final linkRepo = LinkRepository(); // создаем инстанс
final allNotesAfterMerge = await _noteRepo.getAllNotes(userId);
    final local = await _noteRepo.getAllNotes(userId);
    final map = {for (var n in local) n.id: n};
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
      await linkRepo.updateLinksForNote(note, allNotesAfterMerge);
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