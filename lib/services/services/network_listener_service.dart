import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ocutune_light_logger/services/sync_use_case.dart';

class NetworkListenerService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.first;
      if (result != ConnectivityResult.none) {
        SyncUseCase.syncAll();
      }
    });
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
