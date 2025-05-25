import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/ble_light_data_listener.dart';
import 'package:ocutune_light_logger/services/services/battery_service.dart';

import '../auth_storage.dart';
import '../services/api_services.dart';

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

  Timer? _batteryTimer;
  BleLightDataListener? _lightDataListener;

  void monitorBluetoothState() {
    _ble.statusStream.listen((status) {
      isBluetoothOn.value = status == BleStatus.ready;
    });
  }

  void startScan() {
    _scanStream?.cancel();
    _scanStream = _ble.scanForDevices(withServices: []).listen(
          (device) {
        final name = device.name.isNotEmpty ? device.name : "Ukendt enhed";
        print("📱 Fundet enhed: $name (${device.id})");
        onDeviceDiscovered?.call(device);
      },
      onError: (e) => print("🚨 Scan fejl: $e"),
    );
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
        if (update.connectionState == DeviceConnectionState.connected) {
          stopScan();
          connectedDevice = device;
          connectedDeviceNotifier.value = device;
          print("✅ Forbundet til: ${device.name}");
          await FlutterForegroundTask.startService(
            notificationTitle: 'Lysmåling aktiv',
            notificationText: 'Din sensor logger lysdata i baggrunden',
          );


          await Future.delayed(const Duration(milliseconds: 500));
          await discoverServices();
          await readBatteryLevel();

          // Batteri upload setup
          _batteryTimer?.cancel();
          Future.delayed(const Duration(seconds: 20), () {
            BatteryService.sendToBackend(batteryLevel: batteryNotifier.value);
          });
          _batteryTimer = Timer.periodic(Duration(minutes: 10), (_) async {
            final level = batteryNotifier.value;
            await BatteryService.sendToBackend(batteryLevel: level);
          });

          // 👇 Ret her: korrekt service ID til characteristic!
          final lightCharacteristic = QualifiedCharacteristic(
            deviceId: device.id,
            serviceId: Uuid.parse("0000181b-0000-1000-8000-00805f9b34fb"), // ✅ KORREKT service!
            characteristicId: Uuid.parse("834419a6-b6a4-4fed-9afb-acbb63465bf7"),
          );

          _lightDataListener = BleLightDataListener(
            lightCharacteristic: lightCharacteristic,
            ble: _ble,
          );

          _lightDataListener!.startPollingReads();
        } else if (update.connectionState == DeviceConnectionState.disconnected) {
          disconnect();
          await FlutterForegroundTask.stopService();
          startScan();
        }
      },
      onError: (error) {
        print("❌ BLE connection fejl: $error");
        disconnect();
      },
    );
  }

  void disconnect() async {
    _connectionStream?.cancel();
    _lightDataListener?.stopListening();
    _lightDataListener = null;

    // Kalder til backend for at afslutte sensoren
    try {
      final patientId = await AuthStorage.getUserId();
      final jwt = await AuthStorage.getToken();
      final sensorId = await ApiService.getSensorIdFromDevice(connectedDevice!.id, jwt!);

      await ApiService.endSensorUse(
        patientId: patientId!,
        sensorId: sensorId!,
        jwt: jwt,
        status: "disconnected",
      );

    } catch (e) {
      print("⚠️ Kunne ikke afslutte sensorbrug: $e");
    }

    connectedDevice = null;
    connectedDeviceNotifier.value = null;
    batteryNotifier.value = 0;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    print("🔌 Forbindelsen er afbrudt");
  }


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
        print('🟩 Service UUID: $service');
        for (final char in service.characteristics) {
          print('  └─ 🔹 Characteristic UUID: $char');
        }
      }
    } catch (e) {
      print('❌ discoverServices-fejl: $e');
    }
  }

  FlutterReactiveBle get bleInstance => _ble;
}
