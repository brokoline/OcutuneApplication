import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';


class NetworkListenerService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.first;
      if (result != ConnectivityResult.none) {
      }
    });
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
