import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/sync_use_case.dart';
import 'package:ocutune_light_logger/services/sync_scheduler.dart';
import 'package:ocutune_light_logger/services/services/network_listener_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      // 1) Locale-format (ikke kritisk hvis fejler)
      try {
        await initializeDateFormatting('da_DK');
      } catch (e) {
        debugPrint('Kunne ikke loade da_DK locale: $e');
      }

      // 2) Init lokal SQLite‐buffer for offline data
      await OfflineStorageService.init();

      // 3) Start netværkslistener
      NetworkListenerService.start();

      // 4) Start periodisk baggrundssync
      SyncScheduler.start(interval: const Duration(minutes: 10));

      // 5) Start første synkronisering i baggrunden
      Future(() async {
        await SyncUseCase.syncAll();
      });

      // 6) Initialiser foreground‐task (Android/iOS)
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

      // 7) UI og cert overrides
      if (!kReleaseMode) {
        HttpOverrides.global = MyHttpOverrides();
      }
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF4C4C4C),
          statusBarIconBrightness: Brightness.light,
        ),
      );
      ErrorWidget.builder = (details) => Center(
        child: Text('🚨 FEJL: ${details.exception}', style: const TextStyle(color: Colors.red)),
      );
    } catch (e, stk) {
      debugPrint('❌ AppInitializer FEJL: $e\n$stk');
    }
  }
}

/// Debug/DEV cert override og logging – kun brug hvis du selv vil logge!
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
    return _LoggingHttpClient(inner);
  }
}

class _LoggingHttpClient implements HttpClient {
  final HttpClient _inner;
  _LoggingHttpClient(this._inner);

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    print('🌐 [GET] $url');
    return _inner.getUrl(url);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    print('📡 [POST] $url');
    return _inner.postUrl(url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    print('🧩 [OPEN] $method $url');
    return _inner.openUrl(method, url);
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Function.apply(_inner.noSuchMethod, [invocation]);
}
