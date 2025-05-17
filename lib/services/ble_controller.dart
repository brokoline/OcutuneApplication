import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class BleController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;

  Function(DiscoveredDevice device)? onDeviceDiscovered;

  void startScan() {
    _scanStream?.cancel();

    print("🔍 Starter BLE scanning...");
    _scanStream = _ble.scanForDevices(withServices: []).listen((device) {
      print("📡 Fundet enhed: ${device.name} (${device.id})");
      onDeviceDiscovered?.call(device);
    }, onError: (e) {
      print("🚨 Fejl ved scanning: $e");
    });
  }


  void stopScan() {
    _scanStream?.cancel();
  }
}
