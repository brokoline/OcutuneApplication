import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/auth_storage.dart';
import '../../../services/ble_lifecycle_handler.dart';
import '../../../controller/ble_controller.dart';
import '../../../services/services/api_services.dart';
import '../../../services/services/battery_service.dart';
import '../../../services/services/ble_polling_service.dart';


class PatientSensorController {
  final String patientId;
  final BleController bleController = BleController();
  final List<DiscoveredDevice> devices = [];
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);
  Timer? _batterySyncTimer;
  BleLifecycleHandler? _lifecycleHandler;
  BlePollingService? _pollingService;

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
    _pollingService?.stopPolling();
    _lifecycleHandler?.stop();
  }

  Future<void> requestPermissionsAndScan(BuildContext context) async {
    final locationStatus = await Permission.location.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

    if (locationStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted) {
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
    await bleController.connectToDevice(device: device, patientId: patientId);

    final jwt = await AuthStorage.getToken();
    if (jwt != null) {
      final sensorId = await ApiService.registerSensorUse(
        patientId: patientId.toString(),
        deviceSerial: device.id,
        jwt: jwt,
      );
      print("✅ Sensor registreret med ID: $sensorId");
    }

    await bleController.discoverServices();

    _lifecycleHandler = BleLifecycleHandler(
      bleController: bleController,
      pollingService: _pollingService!,
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
      } catch (e) {
        print("⚠️ Batteri-upload fejlede: $e");
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forbundet til: ${device.name}')),
    );
  }

  void disconnectFromDevice(BuildContext context) {
    _batterySyncTimer?.cancel();
    _pollingService?.stopPolling();
    bleController.disconnect();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forbindelsen blev afbrudt')),
    );
  }
}
