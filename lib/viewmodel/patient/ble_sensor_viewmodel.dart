import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../../services/controller/ble_controller.dart';
import '../../services/services/api_services.dart';
import '../../services/services/battery_service.dart';
import '../../services/ble_lifecycle_handler.dart';
import '../../services/auth_storage.dart';
import '../../services/services/ble_polling_service.dart';

class BleSensorViewModel extends ChangeNotifier {
  final String patientId;
  final BleController _bleController;
  final BlePollingService _pollingService;

  final List<DiscoveredDevice> _devices = [];
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);

  Timer? _batterySyncTimer;
  BleLifecycleHandler? _lifecycleHandler;

  BleSensorViewModel({
    required this.patientId,
    required BleController bleController,
    required BlePollingService pollingService,
  })  : _bleController = bleController,
        _pollingService = pollingService;

  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  void init() {
    _bleController.onDeviceDiscovered = (device) {
      if (!_devices.any((d) => d.id == device.id)) {
        _devices.add(device);
        devicesNotifier.value = List.from(_devices);
      }
    };

    _bleController.monitorBluetoothState();
  }

  void dispose() {
    _batterySyncTimer?.cancel();
    _pollingService.stopPolling();
    _lifecycleHandler?.stop();
    super.dispose();
  }

  Future<bool> requestPermissions() async {
    // Brug en permission-handler uden kontekst
    // Dette skal håndteres i View og kalde videre herfra hvis true
    return true;
  }

  void startScanning() {
    _devices.clear();
    devicesNotifier.value = [];
    _bleController.startScan();
  }

  Future<String?> connectToDevice(DiscoveredDevice device) async {
    await _bleController.connectToDevice(device: device, patientId: patientId);

    final jwt = await AuthStorage.getToken();
    String? sensorId;

    if (jwt != null) {
      sensorId = await ApiService.registerSensorUse(
        patientId: patientId.toString(),
        deviceSerial: device.id,
        jwt: jwt,
      );
    }

    await _bleController.discoverServices();

    _lifecycleHandler = BleLifecycleHandler(
      bleController: _bleController,
      pollingService: _pollingService,
    );
    _lifecycleHandler?.start();
    _lifecycleHandler?.updateDevice(device: device, patientId: patientId);

    _batterySyncTimer?.cancel();
    _batterySyncTimer = Timer.periodic(Duration(minutes: 10), (_) async {
      try {
        if (BleController.connectedDevice != null) {
          final batteryLevel = BleController.batteryNotifier.value;
          await BatteryService.sendToBackend(batteryLevel: batteryLevel);
        }
      } catch (_) {}
    });

    return sensorId;
  }

  void disconnectFromDevice() {
    _batterySyncTimer?.cancel();
    _pollingService.stopPolling();
    _bleController.disconnect();
  }
}
