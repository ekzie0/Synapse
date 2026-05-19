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
  
  // Запуск автосинхронизации
  Future<void> startAutoSync(BuildContext context) async {
    if (_isAutoSyncRunning) return;
    
    _isAutoSyncRunning = true;
    _syncStatus = 'Запуск...';
    notifyListeners();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser!.id!;
    await _syncService.startAutoSync(userId);
    
    _syncService.setOnSyncComplete(() {
      _syncStatus = 'Синхронизация завершена';
      notifyListeners();
      
      final folderProvider = Provider.of<FolderProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      folderProvider.loadAllData(auth.currentUser!.id!);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (_syncStatus == 'Синхронизация завершена') {
          _syncStatus = 'Готов';
          notifyListeners();
        }
      });
    });
    
    _syncStatus = 'Готов';
    notifyListeners();
  }
  
  // Остановка автосинхронизации
  Future<void> stopAutoSync() async {
    await _syncService.stopAutoSync();
    _isAutoSyncRunning = false;
    _syncStatus = 'Остановлен';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _syncService.stopAutoSync();
    super.dispose();
  }
}