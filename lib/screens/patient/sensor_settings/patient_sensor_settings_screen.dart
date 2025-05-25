import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/controller/ble_controller.dart';
import 'package:ocutune_light_logger/services/ble_lifecycle_handler.dart';
import 'package:ocutune_light_logger/services/services/ble_polling_service.dart';

import '../../../services/auth_storage.dart';
import '../../../services/services/api_services.dart';
import '../../../services/services/battery_service.dart';

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
  BlePollingService? _pollingService;

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
  }

  @override
  void dispose() {
    _batterySyncTimer?.cancel();
    _pollingService?.stopPolling();
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

    final jwt = await AuthStorage.getToken();
    if (jwt != null) {
      final sensorId = await ApiService.registerSensorUse(
        patientId: widget.patientId,
        deviceSerial: device.id,
        jwt: jwt,
      );
      print("✅ Sensor registreret med ID: $sensorId");
    }

    await _bleController.discoverServices();


    // Start Lifecycle handler
    _lifecycleHandler = BleLifecycleHandler(
      bleController: _bleController,
      pollingService: _pollingService!,
    );
    _lifecycleHandler?.start();
    _lifecycleHandler?.updateDevice(device: device, patientId: widget.patientId);

    // 🔋 Start batteri-timer
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


    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forbundet til: ${device.name}')),
      );
    }
  }


  void _disconnectFromDevice() {
    _batterySyncTimer?.cancel();
    _pollingService?.stopPolling();
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
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
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
            const SizedBox(height: 20),
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
                    backgroundColor: defaultBoxRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                  child: Text(
                    'Ingen enheder fundet',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
                    : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color.fromRGBO(255, 255, 255, 0.1),
                          ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final connectedDevice =
                                  BleController.connectedDevice;
                              if (connectedDevice == null ||
                                  connectedDevice.id != device.id) {
                                _connectToDevice(device);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            hoverColor: const Color.fromRGBO(
                                255, 255, 255, 0.1),
                            splashColor: const Color.fromRGBO(
                                255, 255, 255, 0.2),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.bluetooth,
                                      color: Colors.white70, size: 20),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.name.isNotEmpty
                                              ? device.name
                                              : 'Ukendt enhed',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          device.id,
                                          style: const TextStyle(
                                            color: Color.fromRGBO(
                                                255, 255, 255, 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ValueListenableBuilder<
                                      DiscoveredDevice?>(
                                    valueListenable: BleController
                                        .connectedDeviceNotifier,
                                    builder:
                                        (context, connectedDevice, _) {
                                      if (connectedDevice?.id ==
                                          device.id) {
                                        return const Icon(
                                          Icons.link,
                                          color: Colors.white70,
                                          size: 20,
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
