import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/auth_storage.dart';
import '../../../services/ble_lifecycle_handler.dart';   // BleLifecycleHandler uden pollingService
import '../../../controller/ble_controller.dart';
import '../../../services/services/api_services.dart';
import '../../../services/services/battery_service.dart';
import '../../../services/services/battery_polling_service.dart'; // Nyt
import '../../../services/services/light_polling_service.dart';   // Nyt

class PatientSensorController {
  final String patientId;
  final BleController bleController = BleController();

  final List<DiscoveredDevice> devices = [];
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);

  Timer? _batterySyncTimer;
  BleLifecycleHandler? _lifecycleHandler;

  // De to nye polling‐services
  BatteryPollingService? _batteryService;
  LightPollingService?   _lightService;

  PatientSensorController({required this.patientId});

  void init() {
    bleController.onDeviceDiscovered = (device) {
      if (!devices.any((d) => d.id == device.id)) {
        devices.add(device);
        devicesNotifier.value = List.from(devices);
      }
    };
    bleController.monitorBluetoothState();
  }

  void dispose() {
    _batterySyncTimer?.cancel();
    _batteryService?.stop();
    _lightService?.stop();
    _lifecycleHandler?.stop();
  }

  Future<void> requestPermissionsAndScan(BuildContext context) async {
    final loc    = await Permission.location.request();
    final scan   = await Permission.bluetoothScan.request();
    final connect= await Permission.bluetoothConnect.request();

    if (loc.isGranted && scan.isGranted && connect.isGranted) {
      startScanning();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du skal give tilladelser for at kunne scanne.'),
        ),
      );
    }
  }

  void startScanning() {
    devices.clear();
    devicesNotifier.value = [];
    bleController.startScan();
  }

  Future<void> connectToDevice(BuildContext context, DiscoveredDevice device) async {
    // 1) Selve BLE-forbindelsen + services discovery
    await bleController.connectToDevice(device: device, patientId: patientId);
    await bleController.discoverServices();

    // 2) Start BatteryPollingService (første upload efter 20s, derefter hver 5 min) :contentReference[oaicite:0]{index=0}
    _batteryService = BatteryPollingService(
      ble: bleController.bleInstance,
      deviceId: device.id,
    );
    await _batteryService!.start();

    // 3) Start LightPollingService (hver 10 s) :contentReference[oaicite:1]{index=1}
    _lightService = LightPollingService(
      ble: bleController.bleInstance,
      deviceId: device.id,
    );
    await _lightService!.start();

    // 4) Lifecycle-handler til resume/reconnect :contentReference[oaicite:2]{index=2}
    _lifecycleHandler = BleLifecycleHandler(bleController: bleController);
    _lifecycleHandler!.start();
    _lifecycleHandler!.updateDevice(device: device, patientId: patientId);

    // 5) (Valgfri ekstra 5-min-timer til manuel battery-upload)
    _batterySyncTimer?.cancel();
    _batterySyncTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _batteryService?.readAndSend(), // kan evt. expose som public metode
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forbundet til: ${device.name}')),
    );
  }

  void disconnectFromDevice(BuildContext context) {
    _batterySyncTimer?.cancel();
    _batteryService?.stop();
    _lightService?.stop();
    bleController.disconnect();
    _lifecycleHandler?.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forbindelsen blev afbrudt')),
    );
  }
}
