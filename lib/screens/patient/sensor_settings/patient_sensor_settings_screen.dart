import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/ble_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class PatientSensorSettingsScreen extends StatefulWidget {
  const PatientSensorSettingsScreen({super.key});

  @override
  State<PatientSensorSettingsScreen> createState() =>
      _PatientSensorSettingsScreenState();
}

class _PatientSensorSettingsScreenState
    extends State<PatientSensorSettingsScreen> {
  final BleController _bleController = BleController();
  final List<DiscoveredDevice> _devices = [];
  DiscoveredDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _bleController.onDeviceDiscovered = (device) {
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
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _devices.clear();
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Du skal give tilladelser for at kunne scanne efter sensorer.'),
        ),
      );
    }
  }

  void _connectToDevice(DiscoveredDevice device) {
    setState(() {
      _connectedDevice = device;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Forbundet til: ${device.name} (${device.id})'),
      ),
    );

    // TODO: Her kan du kalde en rigtig BLE connect metode, fx via flutter_reactive_ble.connectToDevice(...)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Sensorindstillinger',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
                fontWeight: FontWeight.w500,
              ),
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
                _connectedDevice != null
                    ? 'Forbundet til: ${_connectedDevice!.name}'
                    : _devices.isEmpty
                    ? 'Bluetooth er slået til.\nIngen sensor forbundet.'
                    : 'Bluetooth er slået til.\n${_devices.length} enhed(er) fundet.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _connectedDevice == null
                  ? _requestPermissionsAndScan
                  : null, // Disable knap hvis allerede forbundet
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(
                _connectedDevice != null
                    ? 'Forbundet til: ${_connectedDevice!.name}'
                    : 'Søg efter sensor',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Tilgængelige enheder',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
                    return ListTile(
                      title: Text(
                        device.name.isNotEmpty
                            ? device.name
                            : 'Ukendt enhed',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        device.id,
                        style: const TextStyle(color: Colors.white70),
                      ),
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
