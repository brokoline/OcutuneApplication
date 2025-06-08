import 'dart:async';
import 'package:flutter/foundation.dart'; // Til ValueNotifier
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../../services/services/battery_polling_service.dart';
import '../../../services/services/light_polling_service.dart';

class BleController {
  static final BleController _instance = BleController._internal();
  factory BleController() => _instance;
  BleController._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  // Callbacks
  Function(DiscoveredDevice device)? onDeviceDiscovered;

  // State
  static DiscoveredDevice? connectedDevice;
  static final ValueNotifier<DiscoveredDevice?> connectedDeviceNotifier = ValueNotifier(null);
  static final ValueNotifier<bool> isBluetoothOn = ValueNotifier(false);
  static final ValueNotifier<int> batteryNotifier = ValueNotifier(0);

  BatteryPollingService? _batteryService;
  LightPollingService?   _lightService;

  /// Lyt på om BT er tændt
  void monitorBluetoothState() {
    _ble.statusStream.listen((status) {
      isBluetoothOn.value = status == BleStatus.ready;
    });
  }

  /// Start scan
  void startScan() {
    _scanStream?.cancel();
    _scanStream = _ble.scanForDevices(withServices: []).listen(
          (device) => onDeviceDiscovered?.call(device),
      onError: (e) => print("🚨 Scan fejl: $e"),
    );
  }

  /// Stop scan
  void stopScan() {
    _scanStream?.cancel();
  }

  /// Forbind til en enhed
  Future<void> connectToDevice({
    required DiscoveredDevice device,
    required String patientId,
  }) async {
    _connectionStream?.cancel();
    _connectionStream = _ble.connectToDevice(id: device.id).listen(
          (update) async {
        if (update.connectionState == DeviceConnectionState.connected) {
          stopScan();
          connectedDevice = device;
          connectedDeviceNotifier.value = device;
          print("✅ Forbundet til: ${device.name}");

          await FlutterForegroundTask.startService(
            notificationTitle: 'Sensor aktiv',
            notificationText: 'Logger data i baggrunden',
          );

          // Start batteri‐polling
          _batteryService = BatteryPollingService(
            ble: _ble,
            deviceId: device.id,
          );
          _batteryService!.start();

          // Start lys‐polling
          _lightService = LightPollingService(
            ble: _ble,
            deviceId: device.id,
          );
          _lightService!.start();

        } else if (update.connectionState == DeviceConnectionState.disconnected) {
          await disconnect();
        }
      },
      onError: (error) {
        print("❌ BLE connection fejl: $error");
        disconnect();
      },
    );
  }

  /// Afbryd forbindelse
  Future<void> disconnect() async {
    _connectionStream?.cancel();
    await FlutterForegroundTask.stopService();

    _batteryService?.stop();
    _lightService?.stop();

    connectedDevice = null;
    connectedDeviceNotifier.value = null;
    batteryNotifier.value = 0;
    print("🔌 Forbindelsen er afbrudt");
  }

  /// Udforsk services og log UUID’er
  Future<void> discoverServices() async {
    if (connectedDevice == null) return;
    try {
      await _ble.discoverAllServices(connectedDevice!.id);
      final services = await _ble.getDiscoveredServices(connectedDevice!.id);
      for (final service in services) {
        print('🟩 Service: $service');
        for (final char in service.characteristics) {
          print('  └─ 🔹 Char: $char');
        }
      }
    } catch (e) {
      print('❌ discoverServices-fejl: $e');
    }
  }

  /// Læs batteriniveau (og opdater `batteryNotifier`)
  Future<void> readBatteryLevel() async {
    if (connectedDevice == null) return;
    try {
      final char = QualifiedCharacteristic(
        deviceId: connectedDevice!.id,
        serviceId: Uuid.parse("180F"),
        characteristicId: Uuid.parse("2A19"),
      );
      final result = await _ble.readCharacteristic(char);
      if (result.isNotEmpty) {
        final level = result[0];
        batteryNotifier.value = level;
        print("🔋 Batteriniveau: $level%");
      }
    } catch (e) {
      print("⚠️ Fejl ved batterilæsning: $e");
    }
  }

  /// Public accessor til den interne BLE-instans
  FlutterReactiveBle get bleInstance => _ble;
}
