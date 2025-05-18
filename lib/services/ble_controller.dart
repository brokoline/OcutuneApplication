import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/ble_light_data_listener.dart';

class BleController {
  static final BleController _instance = BleController._internal();
  factory BleController() => _instance;
  BleController._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  Function(DiscoveredDevice device)? onDeviceDiscovered;

  static DiscoveredDevice? connectedDevice;
  static final ValueNotifier<DiscoveredDevice?> connectedDeviceNotifier = ValueNotifier(null);
  static final ValueNotifier<int> batteryNotifier = ValueNotifier(0);
  static final ValueNotifier<bool> isBluetoothOn = ValueNotifier(false);

  BleLightDataListener? _lightDataListener;

  void monitorBluetoothState() {
    _ble.statusStream.listen((status) {
      isBluetoothOn.value = status == BleStatus.ready;
    });
  }

  void startScan() {
    _scanStream?.cancel();
    _scanStream = _ble.scanForDevices(withServices: []).listen((device) {
      final name = device.name.isNotEmpty ? device.name : "Ukendt enhed";
      print("📡 Fundet enhed: $name (${device.id})");
      onDeviceDiscovered?.call(device);
    }, onError: (e) {
      print("🚨 Scan fejl: $e");
    });
  }

  void stopScan() {
    _scanStream?.cancel();
  }

  Future<void> connectToDevice({
    required DiscoveredDevice device,
    required int patientId,
  }) async {
    _connectionStream?.cancel();

    _connectionStream = _ble.connectToDevice(id: device.id).listen(
          (update) async {
        try {
          if (update.connectionState == DeviceConnectionState.connected) {
            stopScan();
            connectedDevice = device;
            connectedDeviceNotifier.value = device;
            print("✅ Forbundet til: ${device.name}");

            final sensorId = device.id.hashCode;

            await Future.delayed(const Duration(milliseconds: 500));
            try {
              await discoverServices();
              await readBatteryLevel();
            } catch (e) {
              print("❌ Fejl under discoverServices(): $e");
            }

            final lightCharacteristic = QualifiedCharacteristic(
              deviceId: device.id,
              serviceId: Uuid.parse("00001fbd-30c2-496b-a199-5710fc709961"),
              characteristicId: Uuid.parse("00001fbe-30c2-496b-a199-5710fc709961"),
            );

            _lightDataListener = BleLightDataListener(
              lightCharacteristic: lightCharacteristic,
              ble: _ble,
              patientId: patientId,
              sensorId: sensorId,
            );

            _lightDataListener!.startListening();
          } else if (update.connectionState == DeviceConnectionState.disconnected) {
            connectedDevice = null;
            connectedDeviceNotifier.value = null;
            batteryNotifier.value = 0;
            print("❌ Forbindelsen mistet.");
            startScan();
          }
        } catch (e) {
          print("❌ Exception i BLE connection: $e");
        }
      },
      onError: (error) {
        print("❌ BLE connection fejl: $error");
        disconnect();
      },
    );
  }

  void disconnect() {
    _connectionStream?.cancel();
    _lightDataListener?.stopListening();
    _lightDataListener = null;
    connectedDevice = null;
    connectedDeviceNotifier.value = null;
    batteryNotifier.value = 0;
    print("🔌 Forbindelsen er afbrudt manuelt");
  }

  Future<void> readBatteryLevel() async {
    if (connectedDevice == null) return;

    try {
      final standardChar = QualifiedCharacteristic(
        deviceId: connectedDevice!.id,
        serviceId: Uuid.parse("180F"),
        characteristicId: Uuid.parse("2A19"),
      );

      final result = await _ble.readCharacteristic(standardChar);
      if (result.isNotEmpty) {
        batteryNotifier.value = result[0];
        print("🔋 Batteri: ${batteryNotifier.value}%");
      }
    } catch (e) {
      print("⚠️ Fejl ved batterilæsning: $e");
    }
  }

  Future<void> discoverServices() async {
    if (connectedDevice == null) return;

    try {
      await _ble.discoverAllServices(connectedDevice!.id);
      final services = await _ble.getDiscoveredServices(connectedDevice!.id);

      for (final service in services) {
        print('🟩 Service UUID: ${service}');
        for (final char in service.characteristics) {
          print('  └─ 🔹 Characteristic UUID: ${char}');
        }
      }
    } catch (e) {
      print('❌ Fejl ved discoverServices: $e');
    }
  }
}
