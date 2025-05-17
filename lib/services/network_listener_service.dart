import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ocutune_light_logger/services/offline_sync_manager.dart';

class NetworkListenerService {
  static StreamSubscription<ConnectivityResult>? _subscription;

  static void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        OfflineSyncManager.syncAll(); // netforbindelse = forsøg at synkronisere
      }
    });
  }

  static void stop() {
    _subscription?.cancel();
  }
}
