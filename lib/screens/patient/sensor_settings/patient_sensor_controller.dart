// lib/controllers/patient_sensor_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../controller/ble_controller.dart';
import '../../../services/ble_lifecycle_handler.dart';

class PatientSensorController {
  final String patientId;
  final BleController bleController;

  final List<DiscoveredDevice> devices = [];
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);

  BleLifecycleHandler? _lifecycleHandler;

  PatientSensorController({ required this.patientId })
      : bleController = BleController();

  /// Skal kaldes fra fx initState() i din View
  void init() {
    bleController.onDeviceDiscovered = (device) {
      if (!devices.any((d) => d.id == device.id)) {
        devices.add(device);
        devicesNotifier.value = List.from(devices);
      }
    };
    bleController.monitorBluetoothState();
  }

  /// Skal kaldes i dispose() i din View
  void dispose() {
    _lifecycleHandler?.stop();
  }

  /// Få de nødvendige tilladelser og start scan
  Future<void> requestPermissionsAndScan(BuildContext context) async {
    final loc     = await Permission.location.request();
    final scan    = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

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

  /// Start scanning (únikt sted i app’en)
  void startScanning() {
    devices.clear();
    devicesNotifier.value = [];
    bleController.startScan();
  }

  /// Forbind til en enhed (alt BLE + polling håndteres i BleController)
  Future<void> connectToDevice(
      BuildContext context,
      DiscoveredDevice device,
      ) async {
    await bleController.connectToDevice(
      device: device,
      patientId: patientId,
    );

    // Opsæt automatisk genopkobling ved resume
    _lifecycleHandler = BleLifecycleHandler(bleController: bleController)
      ..start()
      ..updateDevice(device: device, patientId: patientId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forbundet til: ${device.name}')),
    );
  }

  /// Afbryd forbindelse (stop polling, background‐service m.m.)
  void disconnectFromDevice(BuildContext context) {
    _lifecycleHandler?.stop();
    bleController.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forbindelsen blev afbrudt')),
    );
  }
}
