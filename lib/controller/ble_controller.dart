import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:synchronized/synchronized.dart';

import '../services/auth_storage.dart';
import '../services/services/api_services.dart';
import '../services/services/battery_polling_service.dart';
import '../services/services/light_polling_service.dart';

class BleController {
  // Singleton-instances
  static final BleController _instance = BleController._internal();
  factory BleController() => _instance;
  BleController._internal();

  // Underliggende BLE-instans
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final Lock _bleLock = Lock();

  // Scan- og connection-subscriptions
  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  // Broadcast for connection updates
  final _connectionUpdatesController = StreamController<ConnectionStateUpdate>.broadcast();

  /// Stream du kan lytte på for at få alle GATT-state opdateringer
  Stream<ConnectionStateUpdate> get connectionStateStream => _connectionUpdatesController.stream;

  // Callback for scanning
  Function(DiscoveredDevice device)? onDeviceDiscovered;

  // State-notifiers til UI
  static final ValueNotifier<DiscoveredDevice?> connectedDeviceNotifier = ValueNotifier(null);
  static final ValueNotifier<bool> isBluetoothOn = ValueNotifier(false);
  static final ValueNotifier<int> batteryNotifier = ValueNotifier(0);

  BatteryPollingService? _batteryService;
  LightPollingService? _lightService;
  LightPollingService? get lightService => _lightService;

  /// Sikker læsning af BLE characteristic
  Future<List<int>> safeReadCharacteristic(QualifiedCharacteristic characteristic) {
    return _bleLock.synchronized(() => _ble.readCharacteristic(characteristic));
  }

  /// Begynd at overvåge bluetooth-status
  void monitorBluetoothState() {
    _ble.statusStream
        .listen((status) => isBluetoothOn.value = status == BleStatus.ready);
  }

  /// Start scan
  void startScan() {
    _scanStream?.cancel();
    _scanStream = _ble.scanForDevices(withServices: []).listen(
      onDeviceDiscovered,
      onError: (e) => debugPrint('🚨 Scan-fejl: $e'),
    );
  }

  void stopScan() => _scanStream?.cancel();

  /// Forbind til device og emit opdateringer til connectionStateStream
  Future<void> connectToDevice({
    required DiscoveredDevice device,
    required String patientId,
  }) async {
    // Ryd op på gammel forbindelse
    _connectionStream?.cancel();

    // Lyt på BLE-forbindelsen
    _connectionStream = _ble.connectToDevice(id: device.id).listen(
          (update) async {
        // Forward update til listeners
        _connectionUpdatesController.add(update);

        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            stopScan();
            connectedDeviceNotifier.value = device;
            debugPrint('✅ Connected to ${device.name}');

            // Kickstart Android-foreground service
            await FlutterForegroundTask.startService(
              notificationTitle: 'Sensor aktiv',
              notificationText: 'Logger data i baggrunden',
            );

            // 1) Discover services + læs batteri
            await _ble.discoverAllServices(device.id);
            await _readBatteryLevel(device.id);

            // 2) Registrér sensoren ÉN gang
            final jwt = await AuthStorage.getToken();
            final sensorId = jwt != null
                ? await ApiService.registerSensorUse(
              patientId: patientId,
              deviceSerial: device.id,
              jwt: jwt,
            )
                : null;
            if (sensorId == null) {
              throw Exception('Kunne ikke registrere sensor');
            }

            // 3) Start BatteryPollingService med kendt sensorId
            _batteryService = BatteryPollingService(
              ble: _ble,
              deviceId: device.id,
              sensorId: sensorId,
            );
            await _batteryService!.start();

            // 4) Discover light-characteristic
            final lightChar = QualifiedCharacteristic(
              deviceId: device.id,
              serviceId: Uuid.parse('0000181b-0000-1000-8000-00805f9b34fb'),
              characteristicId: Uuid.parse('834419a6-b6a4-4fed-9afb-acbb63465bf7'),
            );

            // 5) Start LightPollingService med samme sensorId
            _lightService = LightPollingService(
              ble: _ble,
              characteristic: lightChar,
              patientId: patientId,
              sensorId: sensorId,
            );
            await _lightService!.start();
            break;

          case DeviceConnectionState.disconnected:
            await disconnect();
            break;

          default:
          // Ignorér connecting/disconnecting
            break;
        }
      },
      onError: (e) {
        debugPrint('❌ BLE-connection-fejl: $e');
        disconnect();
      },
    );
  }

  /// Afbryd og ryd op
  Future<void> disconnect() async {
    _connectionStream?.cancel();
    await FlutterForegroundTask.stopService();

    await _batteryService?.stop();
    await _lightService?.stop();

    connectedDeviceNotifier.value = null;
    batteryNotifier.value = 0;
    debugPrint('🔌 Connection afbrudt');
  }

  // Hjælper: læs batteri-char én gang
  Future<void> _readBatteryLevel(String deviceId) async {
    try {
      final char = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('0000180f-0000-1000-8000-00805f9b34fb'),
        characteristicId: Uuid.parse('00002a19-0000-1000-8000-00805f9b34fb'),
      );
      final data = await _ble.readCharacteristic(char);
      if (data.isNotEmpty) {
        batteryNotifier.value = data[0];
        debugPrint('Batteri: ${data[0]}%');
      }
    } catch (e) {
      debugPrint('Fejl ved batteri-læsning: $e');
    }
  }

  // discover services API
  Future<List<DiscoveredService>> discoverServices() async {
    final device = connectedDeviceNotifier.value;
    if (device == null) {
      throw StateError('Ingen BLE-enhed forbundet – kan ikke discoverServices()');
    }
    await _ble.discoverAllServices(device.id);
    return _ble.discoverServices(device.id);
  }

  FlutterReactiveBle get bleInstance => _ble;
}