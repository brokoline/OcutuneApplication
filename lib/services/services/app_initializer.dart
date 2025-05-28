import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/sync_use_case.dart';
import 'package:ocutune_light_logger/services/services/network_listener_service.dart';
import 'package:ocutune_light_logger/services/sync_scheduler.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      await initializeDateFormatting('da_DK', null);
      await Future.delayed(const Duration(milliseconds: 50));

      await OfflineStorageService.init();
      await Future.delayed(const Duration(milliseconds: 50));

      await OfflineSyncManager.syncAll();
      await Future.delayed(const Duration(milliseconds: 50));

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
      print('❌ AppInitializer FEJL: $e');
    }
  }
}
