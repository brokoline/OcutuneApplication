// lib/controllers/customer_sensor_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ocutune_light_logger/controller/ble_controller.dart';
import 'package:ocutune_light_logger/services/ble_lifecycle_handler.dart';

class CustomerSensorController {
  final String customerId;
  final BleController bleController;

  /// Privat liste over fundne devices
  final List<DiscoveredDevice> _devices = [];

  /// Notifier som UI kan lytte på
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);

  /// Gør listen tilgængelig uden for klassen
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  BleLifecycleHandler? _lifecycleHandler;

  CustomerSensorController({ required this.customerId })
      : bleController = BleController();

  /// Skal kaldes én gang fra fx initState()
  void init() {
    // Når en ny device bliver fundet
    bleController.onDeviceDiscovered = (device) {
      if (!_devices.any((d) => d.id == device.id)) {
        _devices.add(device);
        devicesNotifier.value = List.unmodifiable(_devices);
      }
    };
    // Start overvågning af bluetooth-status
    bleController.monitorBluetoothState();
  }

  /// Skal kaldes fra dispose()
  void dispose() {
    _lifecycleHandler?.stop();
    devicesNotifier.dispose();
  }

  /// Spørg om nødvendige tilladelser, før der scannes
  Future<void> requestPermissionsAndScan(BuildContext context) async {
    final statusLocation = await Permission.locationWhenInUse.request();
    final statusScan     = await Permission.bluetoothScan.request();
    final statusConnect  = await Permission.bluetoothConnect.request();

    if (statusLocation.isGranted &&
        statusScan.isGranted &&
        statusConnect.isGranted) {
      startScanning();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du skal give tilladelser for at kunne scanne.'),
        ),
      );
    }
  }

  /// Nulstil liste og start BLE-scanningen
  void startScanning() {
    _devices.clear();
    devicesNotifier.value = [];
    bleController.startScan();
  }

  /// Forbind til en valgt device og sæt lifecycle‐handler op
  Future<void> connectToDevice(
      BuildContext context,
      DiscoveredDevice device,
      ) async {
    try {
      await bleController.connectToDevice(
        device: device,
        patientId: customerId, // <--- NB: behold "patientId" hvis BLE-controlleren forventer det!
      );

      // Opsæt genopkobling ved app-lifecycle
      _lifecycleHandler = BleLifecycleHandler(
        bleController: bleController,
      )
        ..start()
        ..updateDevice(
          device: device,
          patientId: customerId, // <--- NB: samme her!
        );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forbundet til: ${device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke forbinde: $e')),
      );
    }
  }

  /// Afbryd forbindelse og fjern lifecycle‐observer
  void disconnectFromDevice(BuildContext context) {
    _lifecycleHandler?.stop();
    bleController.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forbindelsen blev afbrudt')),
    );
  }
}
