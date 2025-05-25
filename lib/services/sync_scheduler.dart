import 'dart:async';
import 'package:ocutune_light_logger/services/offline_sync_manager.dart';

class SyncScheduler {
  static Timer? _syncTimer;
  static bool _isRunning = false;

  static void start({Duration interval = const Duration(minutes: 10)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) async {
      if (_isRunning) return;
      _isRunning = true;
      try {
        print("🔄 Starter offline synkronisering...");
        await OfflineSyncManager.syncAll();
      } catch (e) {
        print("❌ Fejl i SyncScheduler: $e");
      } finally {
        _isRunning = false;
      }
    });
  }

  static void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

