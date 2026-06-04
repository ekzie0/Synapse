import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/services/sync_service.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  
  bool _isAutoSyncRunning = false;
  String _syncStatus = 'Ожидание';
  
  bool get isAutoSyncRunning => _isAutoSyncRunning;
  String get syncStatus => _syncStatus;
  
  Future<void> startAutoSync(BuildContext context) async {
    if (_isAutoSyncRunning) return;
    
    _isAutoSyncRunning = true;
    _syncStatus = 'Запуск...';
    notifyListeners();
    
    // Безопасно получаем ID пользователя и ссылку на FolderProvider до асинхронных операций
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final userId = authProvider.currentUser!.id!;
    
    // Настраиваем коллбэк завершения БЕЗ использования BuildContext внутри
    _syncService.setOnSyncComplete(() {
      // Проверяем, не выключил ли пользователь синхронизацию, пока она шла
      if (!_isAutoSyncRunning) return;

      _syncStatus = 'Синхронизация завершена';
      notifyListeners();
      
      // Обновляем данные папок (используем сохраненную ссылку, это безопасно)
      folderProvider.loadAllData(userId);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (_syncStatus == 'Синхронизация завершена' && _isAutoSyncRunning) {
          _syncStatus = 'Готов';
          notifyListeners();
        }
      });
    });

    try {
      // Запускаем сервис. Если метод внутри SyncService блокирующий, 
      // unawaited вызов (без await) или фоновый поток не дадут интерфейсу зависнуть.
      // Если метод возвращает Future сразу, await ничему не помешает.
      await _syncService.startAutoSync(userId);
      
      _syncStatus = 'Готов';
    } catch (e) {
      _isAutoSyncRunning = false;
      _syncStatus = 'Ошибка запуска: $e';
    } finally {
      notifyListeners();
    }
  }
  
  Future<void> stopAutoSync() async {
    // Сразу меняем флаг в false, чтобы UI мгновенно отжал ползунок,
    // даже если сокеты будут закрываться пару секунд.
    _isAutoSyncRunning = false;
    _syncStatus = 'Остановка...';
    notifyListeners();

    try {
      await _syncService.stopAutoSync();
      _syncStatus = 'Остановлен';
    } catch (e) {
      _syncStatus = 'Ошибка при остановке';
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // В dispose нельзя вызывать notifyListeners(), поэтому просто тушим сервис
    _syncService.stopAutoSync();
    super.dispose();
  }
}