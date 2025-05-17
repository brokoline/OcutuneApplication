import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/ble_controller.dart';
import 'package:ocutune_light_logger/services/battery_service.dart';
import 'package:ocutune_light_logger/services/light_data_service.dart';

class PatientSensorSettingsScreen extends StatefulWidget {
  const PatientSensorSettingsScreen({super.key});

  @override
  State<PatientSensorSettingsScreen> createState() => _PatientSensorSettingsScreenState();
}

class _PatientSensorSettingsScreenState extends State<PatientSensorSettingsScreen> {
  final _bleController = BleController();
  final List<DiscoveredDevice> _devices = [];
  Timer? _batterySyncTimer;

  @override
  void initState() {
    super.initState();
    _bleController.onDeviceDiscovered = (device) {
      print('📡 Fundet enhed: ${device.name} (${device.id})');
      if (!_devices.any((d) => d.id == device.id)) {
        setState(() {
          _devices.add(device);
        });
      }
    };
  }

  @override
  void dispose() {
    _bleController.stopScan();
    _batterySyncTimer?.cancel();
    super.dispose();
  }

  void _startScanning() {
    print('🔍 Starter scanning...');
    setState(() {
      _devices.clear();
    });
    _bleController.startScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    print('🔐 Anmoder om tilladelser...');
    final locationStatus = await Permission.location.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

    if (locationStatus.isGranted && bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted) {
      print('✅ Tilladelser givet, starter scanning');
      _startScanning();
    } else {
      print('❌ Tilladelser nægtet');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du skal give tilladelser for at kunne scanne efter sensorer.')),
      );
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    print('🔗 Forbinder til ${device.name} (${device.id})...');
    await _bleController.connectToDevice(device);
    await _bleController.readBatteryLevel();

    final batteryLevel = BleController.batteryNotifier.value;

    await BatteryService.sendToBackend(
      patientId: 1,
      sensorId: 2,
      batteryLevel: batteryLevel,
    );

    _batterySyncTimer?.cancel();
    _batterySyncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (BleController.connectedDevice != null) {
        await _bleController.readBatteryLevel();
        final battery = BleController.batteryNotifier.value;
        await BatteryService.sendToBackend(
          patientId: 1,
          sensorId: 2,
          batteryLevel: battery,
        );

        await LightDataService.sendToBackend(
          patientId: 1,
          sensorId: 2,
          luxLevel: 123.4,
          melanopicEdi: 24.3,
          der: 0.76,
          illuminance: 180.2,
          spectrum: [0.1, 0.2, 0.3],
          lightType: 'LED',
          exposureScore: 88.5,
          actionRequired: false,
        );
      }
    });

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forbundet til: ${device.name} (${device.id})')),
    );
  }

  Color _batteryColor(int level) {
    if (level >= 25) return Colors.green;
    if (level >= 10) return Colors.orange;
    return Colors.red;
  }

  IconData _batteryIcon(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = BleController.connectedDevice;

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Sensorindstillinger',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                connectedDevice != null
                    ? 'Forbundet til: ${connectedDevice.name}'
                    : _devices.isEmpty
                    ? 'Bluetooth er slået til.\nIngen sensor forbundet.'
                    : 'Bluetooth er slået til.\n${_devices.length} enhed(er) fundet.',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            if (connectedDevice != null)
              ValueListenableBuilder<int>(
                valueListenable: BleController.batteryNotifier,
                builder: (context, batteryLevel, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_batteryIcon(batteryLevel), color: _batteryColor(batteryLevel)),
                      const SizedBox(width: 8),
                      Text('Batteri: $batteryLevel%', style: TextStyle(color: _batteryColor(batteryLevel))),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: connectedDevice == null ? _requestPermissionsAndScan : null,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(
                connectedDevice != null ? 'Forbundet til: ${connectedDevice.name}' : 'Søg efter sensor',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tilgængelige enheder',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
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
                    ? const Center(child: Text('Ingen enheder fundet', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(
                        device.name.isNotEmpty ? device.name : 'Ukendt enhed',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(device.id, style: const TextStyle(color: Colors.white70)),
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
