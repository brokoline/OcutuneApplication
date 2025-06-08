import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../controller/ble_controller.dart';
import '../../services/auth_storage.dart';
import '../../services/services/api_services.dart';

class BleSensorViewModel extends ChangeNotifier {
  final String patientId;
  final BleController _bleController;

  final List<DiscoveredDevice> _devices = [];
  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);

  BleSensorViewModel({
    required this.patientId,
    required BleController bleController,
  }) : _bleController = bleController;

  void init() {
    _bleController.onDeviceDiscovered = (device) {
      if (!_devices.any((d) => d.id == device.id)) {
        _devices.add(device);
        devicesNotifier.value = List.from(_devices);
      }
    };
    _bleController.monitorBluetoothState();
  }

  @override
  void dispose() {
    _bleController.disconnect();
    super.dispose();
  }

  void startScanning() => _bleController.startScan();

  Future<String?> connectToDevice(DiscoveredDevice device) async {
    // 1) BleController.connectToDevice starter også
    //    BatteryPollingService & LightPollingService
    await _bleController.connectToDevice(
      device: device,
      patientId: patientId,
    );
    await _bleController.discoverServices();

    // 2) Registrér sensoren (hvis du stadig vil vise sensorId tilbage til UI)
    final jwt = await AuthStorage.getToken();
    if (jwt == null) return null;
    return await ApiService.registerSensorUse(
      patientId: patientId,
      deviceSerial: device.id,
      jwt: jwt,
    );
  }

  void disconnectFromDevice() {
    _bleController.disconnect();
  }
}
