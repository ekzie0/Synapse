import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/database/repositories/note_repository.dart';

class SyncService {
  static const int _port = 8080;
  static const int _broadcastPort = 8081;
  
  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  List<IOWebSocketChannel> _clients = [];
  Set<String> _syncedDevices = {};
  Timer? _broadcastTimer;
  bool _isRunning = false;
  
  final NoteRepository _noteRepo = NoteRepository();
  
  Future<void> startAutoSync(int userId) async {
    if (_isRunning) return;
    _isRunning = true;
    await _startServer(userId);
    await _startBroadcast();
    _startUdpListener(userId);
  }
  
  Future<void> stopAutoSync() async {
    _isRunning = false;
    _broadcastTimer?.cancel();
    _udpSocket?.close();
    await _stopServer();
  }
  
  Future<void> _startServer(int userId) async {
    final ip = await _getLocalIp();
    if (ip == null) return;
    
    _server = await HttpServer.bind(InternetAddress(ip), _port);
    _server!.listen((HttpRequest request) async {
      if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
        final WebSocket webSocket = await WebSocketTransformer.upgrade(request);
        final channel = IOWebSocketChannel(webSocket);
        _clients.add(channel);
        channel.stream.listen((data) {
          _handleData(data, userId, channel);
        }, onDone: () {
          _clients.remove(channel);
        });
      }
    });
  }
  
  Future<void> _startBroadcast() async {
    final ip = await _getLocalIp();
    if (ip == null) return;
    
    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final message = utf8.encode(jsonEncode({
        'type': 'synapse_discovery',
        'ip': ip,
        'port': _port,
        'name': await _getDeviceName(),
      }));
      socket.send(message, InternetAddress('255.255.255.255'), _broadcastPort);
      socket.close();
    });
  }
  
  void _startUdpListener(int userId) async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _udpSocket!.receive();
        if (datagram != null) {
          final msg = utf8.decode(datagram.data);
          try {
            final data = jsonDecode(msg);
            if (data['type'] == 'synapse_discovery') {
              final id = '${data['ip']}:${data['port']}';
              if (!_syncedDevices.contains(id)) {
                _syncedDevices.add(id);
                _connectAndSync(data['ip'], data['port'], userId);
              }
            }
          } catch (_) {}
        }
      }
    });
  }
  
  Future<void> _connectAndSync(String ip, int port, int userId) async {
    try {
      final channel = IOWebSocketChannel.connect(Uri.parse('ws://$ip:$port/ws'));
      final notes = await _noteRepo.getAllNotes(userId);
      channel.sink.add(jsonEncode({'type': 'sync', 'notes': _notesToJson(notes)}));
      channel.stream.listen((res) async {
        final data = jsonDecode(res);
        if (data['type'] == 'sync') {
          await _mergeNotes(data['notes'], userId);
          _onSync?.call();
        }
        await channel.sink.close();
      });
    } catch (_) {}
  }
  
  Future<void> _handleData(dynamic data, int userId, IOWebSocketChannel channel) async {
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
    final local = await _noteRepo.getAllNotes(userId);
    final map = {for (var n in local) n.id: n};
    for (var n in notesData) {
      final note = Note(
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
    if (_server != null) await _server!.close(force: true);
    for (var c in _clients) await c.sink.close();
    _clients.clear();
  }
  
  Future<String?> _getLocalIp() async {
    try {
      return await NetworkInfo().getWifiIP();
    } catch (_) {
      return null;
    }
  }
  
  Future<String> _getDeviceName() async {
    try {
      return await NetworkInfo().getWifiName() ?? Platform.operatingSystem;
    } catch (_) {
      return Platform.operatingSystem;
    }
  }
  
  VoidCallback? _onSync;
  void setOnSyncComplete(VoidCallback callback) => _onSync = callback;
}