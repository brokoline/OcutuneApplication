// lib/services/app_initializer.dart

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/sync_use_case.dart';
import 'package:ocutune_light_logger/services/services/network_listener_service.dart';
import 'package:ocutune_light_logger/services/sync_scheduler.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      // 1) Sæt lokal dato‐formatering (dansksprogede datoer)
      await initializeDateFormatting('da_DK', null);
      await Future.delayed(const Duration(milliseconds: 50));

      // 2) Initialiser OfflineStorageService (opretter db og tabeller)
      await OfflineStorageService.init();
      await Future.delayed(const Duration(milliseconds: 50));

      // 3) Rens alle “light”‐poster, der mangler eller har ugyldig sensor_id
      await OfflineStorageService.deleteInvalidSensorData();
      await Future.delayed(const Duration(milliseconds: 50));

      // 4) Udfør synkronisering af alle usynkroniserede rækker
      await SyncUseCase.syncAll();
      await Future.delayed(const Duration(milliseconds: 50));

      // 5) Start periodisk synkroniserings‐scheduler (hver 10. minut)
      SyncScheduler.start(interval: const Duration(minutes: 10));

      // 6) Start at lytte på netværksændringer (så vi kan synkronisere ved genopkobling)
      NetworkListenerService.start();

      // 7) Initialisér foreground‐task (bruges til at holde bg‐service kørende)
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
