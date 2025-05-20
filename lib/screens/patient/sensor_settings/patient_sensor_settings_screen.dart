import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/ble_controller.dart';
import 'package:ocutune_light_logger/services/battery_service.dart';
import 'package:ocutune_light_logger/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/ble_lifecycle_handler.dart';

class PatientSensorSettingsScreen extends StatefulWidget {
  final int patientId;

  const PatientSensorSettingsScreen({super.key, required this.patientId});

  @override
  State<PatientSensorSettingsScreen> createState() =>
      _PatientSensorSettingsScreenState();
}

class _PatientSensorSettingsScreenState
    extends State<PatientSensorSettingsScreen> {
  final _bleController = BleController();
  final List<DiscoveredDevice> _devices = [];
  Timer? _batterySyncTimer;
  BleLifecycleHandler? _lifecycleHandler;

  @override
  void initState() {
    super.initState();

    _bleController.onDeviceDiscovered = (device) {
      if (!_devices.any((d) => d.id == device.id)) {
        if (mounted) {
          setState(() {
            _devices.add(device);
          });
        }
      }
    };

    _bleController.monitorBluetoothState();
    _lifecycleHandler = BleLifecycleHandler(bleController: _bleController);
    _lifecycleHandler?.start();
  }

  @override
  void dispose() {
    _batterySyncTimer?.cancel();
    _lifecycleHandler?.stop();
    super.dispose();
  }

  void _startScanning() {
    if (mounted) {
      setState(() {
        _devices.clear();
      });
    }
    _bleController.startScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    final locationStatus = await Permission.location.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

    if (locationStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted) {
      _startScanning();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Du skal give tilladelser for at kunne scanne.'),
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    await _bleController.connectToDevice(
      device: device,
      patientId: widget.patientId,
    );

    await _bleController.discoverServices();
    await _bleController.readBatteryLevel();

    final batteryLevel = BleController.batteryNotifier.value;
    final sensorId = device.id.hashCode;

    try {
      await BatteryService.sendToBackend(
        patientId: widget.patientId,
        sensorId: sensorId,
        batteryLevel: batteryLevel,
      );
    } catch (_) {
      await OfflineStorageService.saveLocally(
        type: 'battery',
        data: {
          "patient_id": widget.patientId,
          "sensor_id": sensorId,
          "battery_level": batteryLevel,
        },
      );
    }

    _batterySyncTimer?.cancel();
    _batterySyncTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
          if (!mounted || BleController.connectedDevice == null) return;

          await _bleController.readBatteryLevel();
          final battery = BleController.batteryNotifier.value;

          try {
            await BatteryService.sendToBackend(
              patientId: widget.patientId,
              sensorId: sensorId,
              batteryLevel: battery,
            );
          } catch (_) {
            await OfflineStorageService.saveLocally(
              type: 'battery',
              data: {
                "patient_id": widget.patientId,
                "sensor_id": sensorId,
                "battery_level": battery,
              },
            );
          }
        });

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forbundet til: ${device.name}')),
      );
    }
  }

  void _disconnectFromDevice() {
    _batterySyncTimer?.cancel();
    _bleController.disconnect();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forbindelsen blev afbrudt')),
    );
  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Sensorforbindelse',
          style: TextStyle(
              color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 1),
                  ValueListenableBuilder<bool>(
                    valueListenable: BleController.isBluetoothOn,
                    builder: (context, isOn, _) {
                      if (!isOn) {
                        return const Text(
                          'Bluetooth er slået fra.',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        );
                      }

                      return ValueListenableBuilder<DiscoveredDevice?>(
                        valueListenable: BleController.connectedDeviceNotifier,
                        builder: (context, device, _) {
                          final connected = device != null;
                          return ValueListenableBuilder<int>(
                            valueListenable: BleController.batteryNotifier,
                            builder: (context, battery, _) {
                              return Text(
                                connected
                                    ? 'Forbundet til: ${device.name}\n🔋 Batteri: $battery%'
                                    : _devices.isEmpty
                                    ? 'Bluetooth er slået til.\nIngen sensor forbundet.'
                                    : 'Bluetooth er slået til.\n${_devices.length} enhed(er) fundet.',
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<DiscoveredDevice?>(
              valueListenable: BleController.connectedDeviceNotifier,
              builder: (context, device, _) {
                if (device == null) {
                  return ElevatedButton.icon(
                    onPressed: _requestPermissionsAndScan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Søg efter sensor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white70,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }

                return ElevatedButton.icon(
                  onPressed: _disconnectFromDevice,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Afbryd forbindelse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Tilgængelige enheder',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: generalBox,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: _devices.isEmpty
                    ? const Center(
                    child: Text('Ingen enheder fundet',
                        style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(
                        device.name.isNotEmpty
                            ? device.name
                            : 'Ukendt enhed',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      subtitle: Text(device.id,
                          style:
                          const TextStyle(color: Colors.white70)),
                      onTap: () => _connectToDevice(device),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
