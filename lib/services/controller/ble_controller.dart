import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/ble_light_data_listener.dart';
import 'package:ocutune_light_logger/services/services/battery_service.dart';

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
    _scanStream = _ble.scanForDevices(withServices: []).listen((device) {
      final name = device.name.isNotEmpty ? device.name : "Ukendt enhed";
      print("📱 Fundet enhed: $name (\${device.id})");
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
            print("✅ Forbundet til: \${device.name}");

            await Future.delayed(const Duration(milliseconds: 500));

            try {
              await discoverServices();
              await readBatteryLevel();

              _batteryTimer?.cancel();
              Future.delayed(const Duration(seconds: 20), () {
                BatteryService.sendToBackend(batteryLevel: batteryNotifier.value);
              });

              _batteryTimer = Timer.periodic(Duration(minutes: 30), (_) async {
                final level = batteryNotifier.value;
                print("🔁 Periodisk batteri-upload: \$level%");
                await BatteryService.sendToBackend(batteryLevel: level);
              });

              await trySensorActivationWrites(device.id);
            } catch (e) {
              print("❌ Fejl under discoverServices/init: $e");
            }

            final lightCharacteristic = QualifiedCharacteristic(
              deviceId: device.id,
              serviceId: Uuid.parse("0000181b-0000-1000-8000-00805f9b34fb"),
              characteristicId: Uuid.parse("834419a6-b6a4-4fed-9afb-acbb63465bf7"),
            );

            _lightDataListener = BleLightDataListener(
              lightCharacteristic: lightCharacteristic,
              ble: _ble,
            );

            _lightDataListener!.startPollingReads();
          } else if (update.connectionState == DeviceConnectionState.disconnected) {
            disconnect();
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

    _batteryTimer?.cancel();
    _batteryTimer = null;

    print("🔌 Forbindelsen er afbrudt manuelt");
  }

  Future<void> trySensorActivationWrites(String deviceId) async {
    final triggerUUIDs = [
      "00001fbf-30c2-496b-a199-5710fc709961",
      "00001fc0-30c2-496b-a199-5710fc709961",
      "00001fc1-30c2-496b-a199-5710fc709961",
    ];

    final valuesToTry = [
      [0x01], [0x00], [0xFF],
      [0x06, 0x08, 0x01],
      [0xA0], [0xAA], [0x01, 0x00],
    ];

    final readCharacteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse("00001fbd-30c2-496b-a199-5710fc709961"),
      characteristicId: Uuid.parse("00001fbe-30c2-496b-a199-5710fc709961"),
    );

    for (final uuid in triggerUUIDs) {
      for (final value in valuesToTry) {
        try {
          final char = QualifiedCharacteristic(
            deviceId: deviceId,
            serviceId: Uuid.parse("00001fbd-30c2-496b-a199-5710fc709961"),
            characteristicId: Uuid.parse(uuid),
          );

          await _ble.writeCharacteristicWithoutResponse(char, value: value);
          print("➡️ Writing \$value to \$uuid...");

          await Future.delayed(Duration(milliseconds: 500));
          final result = await _ble.readCharacteristic(readCharacteristic);
          print("🔍 Read after \$value → \$result");

          if (result.isNotEmpty) {
            print("✅ SUCCESS! Data received after writing \$value to \$uuid");
            return;
          }
        } catch (e) {
          print("❌ Error writing to \$uuid with \$value: $e");
        }
      }
    }

    print("✅ Færdig med at prøve aktiverings-writes.");
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
        print("🔋 Batteri: \${batteryNotifier.value}%");
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
        print('🟩 Service UUID: \$service');
        for (final char in service.characteristics) {
          print('  └─ 🔹 Characteristic UUID: \$char');
        }
      }
    } catch (e) {
      print('❌ Fejl ved discoverServices: $e');
    }
  }

  FlutterReactiveBle get bleInstance => _ble;
}