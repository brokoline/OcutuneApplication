import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ocutune_light_logger/controller/ble_controller.dart';
import 'package:ocutune_light_logger/services/ble_lifecycle_handler.dart';

class CustomerSensorController {
  final String customerId;
  final BleController bleController;

  final List<DiscoveredDevice> _devices = [];
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);

  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  BleLifecycleHandler? _lifecycleHandler;

  CustomerSensorController({ required this.customerId })
      : bleController = BleController();

  void init() {
    bleController.onDeviceDiscovered = (device) {
      if (!_devices.any((d) => d.id == device.id)) {
        _devices.add(device);
        devicesNotifier.value = List.unmodifiable(_devices);
      }
    };
    bleController.monitorBluetoothState();
  }

  void dispose() {
    _lifecycleHandler?.stop();
    devicesNotifier.dispose();
  }

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

  void startScanning() {
    _devices.clear();
    devicesNotifier.value = [];
    bleController.startScan();
  }

  Future<void> connectToDevice(
      BuildContext context,
      DiscoveredDevice device,
      ) async {
    try {
      await bleController.connectToDevice(
        device: device,
        patientId: customerId,
      );

      _lifecycleHandler = BleLifecycleHandler(
        bleController: bleController,
      )
        ..start()
        ..updateDevice(
          device: device,
          patientId: customerId,
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

  void disconnectFromDevice(BuildContext context) {
    _lifecycleHandler?.stop();
    bleController.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forbindelsen blev afbrudt')),
    );
  }
}
