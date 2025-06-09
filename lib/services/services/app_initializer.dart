// lib/services/app_initializer.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
//import 'package:ocutune_light_logger/services/sync_use_case.dart';
import 'package:ocutune_light_logger/services/services/network_listener_service.dart';
//import 'package:ocutune_light_logger/services/sync_scheduler.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      // 1) Lokalt datoformat (da_DK)
      await initializeDateFormatting('da_DK', null);
      await Future.delayed(const Duration(milliseconds: 50));

      // 2) Initialiser SQLite (opretter unsynced_data og patient_sensor_log og dine batteri‐tabeller)
      await OfflineStorageService.init();
      await Future.delayed(const Duration(milliseconds: 50));

      // 3) Synkroniser alle resterende usynkroniserede data (både batteri og light)
      //await SyncUseCase.syncAll();
      await Future.delayed(const Duration(milliseconds: 50));

      // 4) Start periodisk baggrunds‐scheduler
      //SyncScheduler.start(interval: const Duration(minutes: 10));

      // 7) Start netværks‐listener
      NetworkListenerService.start();

      // 8) Initialiser foreground‐task (Android/iOS)
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
