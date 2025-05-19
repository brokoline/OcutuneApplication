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
      print("\ud83d\udcf1 Fundet enhed: $name (\${device.id})");
      onDeviceDiscovered?.call(device);
    }, onError: (e) {
      print("\ud83d\udea8 Scan fejl: $e");
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
            print("\u2705 Forbundet til: \${device.name}");

            final sensorId = device.id.hashCode;

            await Future.delayed(const Duration(milliseconds: 500));

            try {
              await discoverServices();
              await readBatteryLevel();
              await trySensorActivationWrites(device.id);
            } catch (e) {
              print("\u274c Fejl under discoverServices/init: $e");
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
            _lightDataListener!.startPollingReads();
            await _lightDataListener!.testReadOnce();

            Future.delayed(const Duration(seconds: 5), () async {
              try {
                final char = QualifiedCharacteristic(
                  deviceId: device.id,
                  serviceId: Uuid.parse("00001fbd-30c2-496b-a199-5710fc709961"),
                  characteristicId: Uuid.parse("00001fbf-30c2-496b-a199-5710fc709961"),
                );
                await _ble.writeCharacteristicWithoutResponse(
                  char,
                  value: [0x06, 0x08, 0x01],
                );
                print("\ud83d\udd01 Re-sendt init-v\u00e6rdi til sensor efter 5 sek.");
                await _lightDataListener?.testReadOnce();
              } catch (e) {
                print("\u274c Fejl ved re-send af init efter delay: $e");
              }
            });
          } else if (update.connectionState == DeviceConnectionState.disconnected) {
            connectedDevice = null;
            connectedDeviceNotifier.value = null;
            batteryNotifier.value = 0;
            print("\u274c Forbindelsen mistet.");
            startScan();
          }
        } catch (e) {
          print("\u274c Exception i BLE connection: $e");
        }
      },
      onError: (error) {
        print("\u274c BLE connection fejl: $error");
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
    print("\ud83d\udd0c Forbindelsen er afbrudt manuelt");
  }

  Future<void> trySensorActivationWrites(String deviceId) async {
    final triggerUUIDs = [
      "00001fbf-30c2-496b-a199-5710fc709961",
      "00001fc0-30c2-496b-a199-5710fc709961",
      "00001fc1-30c2-496b-a199-5710fc709961",
    ];

    final valuesToTry = [
      [0x01],
      [0x00],
      [0xFF],
      [0x06, 0x08, 0x01],
      [0xA0],
      [0xAA],
      [0x01, 0x00],
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
          print("\u2794 Writing $value to $uuid...");

          await Future.delayed(Duration(milliseconds: 500));

          final result = await _ble.readCharacteristic(readCharacteristic);
          print("\ud83d\udd0d Read after $value → $result");

          if (result.isNotEmpty) {
            print("\u2705 SUCCESS! Data received after writing $value to $uuid");
            return; // Stop test hvis data modtages
          }
        } catch (e) {
          print("\u274c Error writing to $uuid with $value: $e");
        }
      }
    }

    print("\u2705 F\u00e6rdig med at pr\u00f8ve aktiverings-writes.");
    await _lightDataListener?.testReadOnce();
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
        print("\ud83d\udd0b Batteri: \${batteryNotifier.value}%");
      }
    } catch (e) {
      print("\u26a0\ufe0f Fejl ved batteril\u00e6sning: $e");
    }
  }

  Future<void> discoverServices() async {
    if (connectedDevice == null) return;

    try {
      await _ble.discoverAllServices(connectedDevice!.id);
      final services = await _ble.getDiscoveredServices(connectedDevice!.id);

      for (final service in services) {
        print('\ud83d\udfe9 Service UUID: \$service');
        for (final char in service.characteristics) {
          print('  └─ \ud83d\udd39 Characteristic UUID: $char');
        }
      }
    } catch (e) {
      print('\u274c Fejl ved discoverServices: $e');
    }
  }
}