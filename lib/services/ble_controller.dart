import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class BleController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;

  Function(DiscoveredDevice device)? onDeviceDiscovered;

  void startScan() {
    _scanStream?.cancel(); // stop tidligere scanning hvis aktiv
    _scanStream = _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name.isNotEmpty) {
        onDeviceDiscovered?.call(device);
      }
    });
  }

  void stopScan() {
    _scanStream?.cancel();
  }
}
