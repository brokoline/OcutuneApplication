import 'dart:async';
import 'dart:typed_data';
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

  static final ValueNotifier<int> batteryNotifier = ValueNotifier(0);
  static DiscoveredDevice? connectedDevice;
  static final ValueNotifier<DiscoveredDevice?> connectedDeviceNotifier = ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>> latestLightData = ValueNotifier({});


  BleLightDataListener? _lightDataListener;

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

      for (int attempt = 0; attempt < 3; attempt++) {
        final result = await _ble.readCharacteristic(standardChar);
        print("🧪 [Standard] Batteri raw: $result");

        if (result.isNotEmpty) {
          batteryNotifier.value = result[0];
          print("🔋 Batteri: ${batteryNotifier.value}%");
          return;
        }

        print("⚠️ Tom værdi fra 2A19, forsøg $attempt");
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final customChar = QualifiedCharacteristic(
        deviceId: connectedDevice!.id,
        serviceId: Uuid.parse("00001fbd-30c2-496b-a199-5710fc709961"),
        characteristicId: Uuid.parse("00001fc1-30c2-496b-a199-5710fc709961"),
      );

      final fallbackResult = await _ble.readCharacteristic(customChar);
      print("🧪 [Fallback] Batteri raw fra 00001fc1: $fallbackResult");

      if (fallbackResult.isNotEmpty) {
        batteryNotifier.value = fallbackResult[0];
        print("🔋 Batteri (fallback): ${batteryNotifier.value}%");
      } else {
        print("❌ Kunne ikke læse batteri fra nogen af karakteristikkerne");
      }
    } catch (e) {
      print("⚠️ Fejl ved batterilæsning: $e");
    }
  }

  Future<Map<String, dynamic>> readLightSensorData() async {
    print("🔎 Forsøger at læse lysdata...");
    if (connectedDevice == null) return {};

    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: connectedDevice!.id,
        serviceId: Uuid.parse("00001fbd-30c2-496b-a199-5710fc709961"),
        characteristicId: Uuid.parse("00001fbe-30c2-496b-a199-5710fc709961"),
      );

      final rawStream = _ble.subscribeToCharacteristic(characteristic).take(1);

      await for (final data in rawStream) {
        print("📦 Lysdata (via notify): $data");

        if (data.isEmpty) continue;

        final buffer = Uint8List.fromList(data).buffer.asByteData();

        final luxLevel = buffer.getFloat32(0, Endian.little);
        final melanopicEdi = buffer.getFloat32(4, Endian.little);
        final der = buffer.getFloat32(8, Endian.little);
        final illuminance = buffer.getFloat32(12, Endian.little);

        return {
          'lux_level': luxLevel,
          'melanopic_edi': melanopicEdi,
          'der': der,
          'illuminance': illuminance,
          'spectrum': [],
          'light_type': 'LED',
          'exposure_score': 80.0,
          'action_required': false,
        };
      }

      return {};
    } catch (e) {
      print("❌ Fejl i lysdata-læsning: $e");
      return {};
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

  Future<void> debugReadAllCharacteristics() async {
    if (connectedDevice == null) {
      print("⚠️ Ingen enhed forbundet til debug-læsning.");
      return;
    }

    try {
      final services = await _ble.getDiscoveredServices(connectedDevice!.id);

      for (final service in services) {
        final serviceId = service.id;
        print("🟩 Debug Service: $serviceId");
        for (final char in service.characteristics) {
          final charId = char.id;
          try {
            final value = await _ble.readCharacteristic(
              QualifiedCharacteristic(
                deviceId: connectedDevice!.id,
                serviceId: serviceId,
                characteristicId: charId,
              ),
            );
            print("📖 READ $charId: $value");
          } catch (e) {
            print("❌ Kunne ikke læse $charId: $e");
          }
        }
      }
    } catch (e) {
      print("⚠️ Fejl under debug-læsning: $e");
    }
  }

  static final ValueNotifier<bool> isBluetoothOn = ValueNotifier(false);

  void monitorBluetoothState() {
    _ble.statusStream.listen((status) {
      isBluetoothOn.value = status == BleStatus.ready;
    });
  }


  void dispose() {}
}
