import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/offline_sync_manager.dart';
import 'package:ocutune_light_logger/services/services/network_listener_service.dart';
import 'package:ocutune_light_logger/services/sync_scheduler.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      await OfflineStorageService.init();
      await OfflineSyncManager.syncAll();
      SyncScheduler.start(interval: const Duration(minutes: 10));
      NetworkListenerService.start();

      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'foreground_service_channel',
          channelName: 'Foreground Service',
          channelDescription: 'Used for background service',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: const ForegroundTaskOptions(),
      );
    } catch (e) {
      debugPrint('❌ Fejl i AppInitializer: $e');
    }
  }
}
