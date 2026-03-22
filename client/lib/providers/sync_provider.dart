import 'package:flutter/material.dart';
import 'package:synapse/services/sync_service.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:provider/provider.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _service = SyncService();
  bool _running = false;
  String _status = 'Ожидание';
  
  bool get isAutoSyncRunning => _running;
  String get syncStatus => _status;
  
  Future<void> startAutoSync(BuildContext context) async {
    if (_running) return;
    _running = true;
    _status = 'Запуск...';
    notifyListeners();
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await _service.startAutoSync(auth.currentUser!.id!);
    
    _service.setOnSyncComplete(() {
      _status = 'Синхронизация завершена';
      notifyListeners();
      
      final folder = Provider.of<FolderProvider>(context, listen: false);
      final a = Provider.of<AuthProvider>(context, listen: false);
      folder.loadRootFolders(a.currentUser!.id!);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (_status == 'Синхронизация завершена') {
          _status = 'Готов';
          notifyListeners();
        }
      });
    });
    
    _status = 'Готов';
    notifyListeners();
  }
  
  Future<void> stopAutoSync() async {
    await _service.stopAutoSync();
    _running = false;
    _status = 'Остановлен';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _service.stopAutoSync();
    super.dispose();
  }
}