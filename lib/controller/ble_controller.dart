// lib/controller/ble_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../services/auth_storage.dart';
import '../services/services/api_services.dart';
import '../services/services/battery_polling_service.dart';
import '../services/services/light_polling_service.dart';

class BleController {
  // Singleton‐instans
  static final BleController _instance = BleController._internal();
  factory BleController() => _instance;
  BleController._internal();

  // Den interne BLE‐instans
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Stream‐subs til scan og connection
  StreamSubscription<DiscoveredDevice>?       _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  // Callback, der kaldes for hver funden enhed under scan
  Function(DiscoveredDevice device)? onDeviceDiscovered;

  // State‐notifiers til UI
  static final ValueNotifier<DiscoveredDevice?> connectedDeviceNotifier = ValueNotifier(null);
  static final ValueNotifier<bool>              isBluetoothOn               = ValueNotifier(false);
  static final ValueNotifier<int>               batteryNotifier             = ValueNotifier(0);

  BatteryPollingService? _batteryService;
  LightPollingService?   _lightService;

  // Begynd at lytte på Bluetooth‐status (tændt/slukket)
  void monitorBluetoothState() {
    _ble.statusStream.listen((status) {
      isBluetoothOn.value = status == BleStatus.ready;
    });
  }

  /// Start scan efter BLE‐enheder (uden services‐filter)
  void startScan() {
    _scanStream?.cancel();
    _scanStream = _ble
        .scanForDevices(withServices: [])
        .listen(onDeviceDiscovered, onError: (e) => print("🚨 Scan fejl: $e"));
  }

  /// Stop igangværende scan
  void stopScan() {
    _scanStream?.cancel();
  }


  /// Forbind til en bestemt enhed og spark alle polling‐services i gang
  Future<void> connectToDevice({
    required DiscoveredDevice device,
    required String patientId,
  }) async {
    // Afmeld evt. tidligere connection‐listener
    _connectionStream?.cancel();

    _connectionStream = _ble.connectToDevice(id: device.id).listen(
          (update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
          // ── 1) Stop scan, opdater UI
            stopScan();
            connectedDeviceNotifier.value = device;
            print("✅ Connected to ${device.name}");

            // ── 2) Start foreground‐service (Android baggrund)
            await FlutterForegroundTask.startService(
              notificationTitle: 'Sensor aktiv',
              notificationText: 'Logger data i baggrunden',
            );

            // ── 3) Discover services + læs batteri straks
            await _ble.discoverAllServices(device.id);
            await _readBatteryLevel(device.id);

            // ── 4) Start BatteryPollingService
            _batteryService = BatteryPollingService(
              ble:      _ble,
              deviceId: device.id,
            );
            await _batteryService!.start();

            // ── 5) Registrér sensor‐brug og start LightPollingService
            final jwt = await AuthStorage.getToken();
            final sensorId = (jwt != null)
                ? await ApiService.registerSensorUse(
              patientId:    patientId,
              deviceSerial: device.id,
              jwt:          jwt,
            )
                : null;

            if (sensorId == null) {
              print("❌ Kunne ikke registrere sensor til lys‐polling");
              return;
            }

            final lightChar = QualifiedCharacteristic(
              deviceId:         device.id,
              serviceId:        Uuid.parse('0000181b-0000-1000-8000-00805f9b34fb'),
              characteristicId: Uuid.parse('834419a6-b6a4-4fed-9afb-acbb63465bf7'),
            );
            _lightService = LightPollingService(
              ble:            _ble,
              characteristic: lightChar,
              patientId:      patientId,
              sensorId:       sensorId,
            );
            await _lightService!.start();
            break;

          case DeviceConnectionState.disconnected:
          // Automatisk reconnect/disconnect‐flow
            await disconnect();
            break;

          default:
          // Ignorér "connecting" og "disconnecting"
            break;
        }
      },
      onError: (e) {
        print("❌ BLE-connection fejl: $e");
        disconnect();
      },
    );
  }

  // Afbryd forbindelse og stop alle polling‐services
  Future<void> disconnect() async {
    _connectionStream?.cancel();
    await FlutterForegroundTask.stopService();

    _batteryService?.stop();
    _lightService?.stop();

    connectedDeviceNotifier.value = null;
    batteryNotifier.value          = 0;
    print("🔌 Connection afbrudt");
  }

  // Intern helper: Læs batteriniveau  én gang
  Future<void> _readBatteryLevel(String deviceId) async {
    try {
      final char = QualifiedCharacteristic(
        deviceId:         deviceId,
        serviceId:        Uuid.parse('180F'),
        characteristicId: Uuid.parse('2A19'),
      );
      final data = await _ble.readCharacteristic(char);
      if (data.isNotEmpty) {
        batteryNotifier.value = data[0];
        print("🔋 Batteri: ${data[0]}%");
      }
    } catch (e) {
      print("⚠️ Fejl ved batteri‐læsning: $e");
    }
  }

  /// Discover services på den pt. forbundne enhed.
  /// Returnerer listen af DiscoveredService
  Future<List<Service>> discoverServices() async {
    final device = connectedDeviceNotifier.value;
    if (device == null) {
      throw StateError('Ingen BLE-enhed tilsluttet – kan ikke discoverServices()');
    }
    // 1) Udfør BLE-discover
    await _ble.discoverAllServices(device.id);
    // 2) Hent og returnér dem
    return await _ble.getDiscoveredServices(device.id);
  }

  /// Giv andre klasser direkte adgang til BLE-instansen, hvis nødvendigt
  FlutterReactiveBle get bleInstance => _ble;
}
