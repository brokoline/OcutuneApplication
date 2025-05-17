import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/foundation.dart';

class BleController {
  static final BleController _instance = BleController._internal();
  factory BleController() => _instance;
  BleController._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  Function(DiscoveredDevice device)? onDeviceDiscovered;

  static final ValueNotifier<int> batteryNotifier = ValueNotifier(0);
  static DiscoveredDevice? connectedDevice;

  void startScan() {
    _scanStream?.cancel();
    _scanStream = _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name.isNotEmpty) {
        onDeviceDiscovered?.call(device);
      }
    }, onError: (e) {
      print("🚨 Scan fejl: $e");
    });
  }

  void stopScan() {
    _scanStream?.cancel();
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    _connectionStream?.cancel();

    _connectionStream = _ble.connectToDevice(id: device.id).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        connectedDevice = device;
        print("✅ Forbundet til: ${device.name}");
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        connectedDevice = null;
        batteryNotifier.value = 0;
        print("❌ Forbindelsen mistet.");
      }
    });
  }

  Future<void> readBatteryLevel() async {
    if (connectedDevice == null) return;

    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: connectedDevice!.id,
        serviceId: Uuid.parse("180F"),
        characteristicId: Uuid.parse("2A19"),
      );
      final result = await _ble.readCharacteristic(characteristic);
      if (result.isNotEmpty) {
        batteryNotifier.value = result[0];
        print("🔋 Batteri: ${batteryNotifier.value}%");
      }
    } catch (e) {
      print("⚠️ Kunne ikke læse batteri: $e");
    }
  }

  void dispose() {
    _scanStream?.cancel();
    _connectionStream?.cancel();
  }
}
