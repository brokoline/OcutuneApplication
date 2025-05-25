import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/controller/ble_controller.dart';
import 'package:ocutune_light_logger/services/services/ble_polling_service.dart';

class BleLifecycleHandler extends WidgetsBindingObserver {
  final BleController bleController;
  final BlePollingService pollingService;

  DiscoveredDevice? _lastDevice;
  String? _lastPatientId;

  BleLifecycleHandler({
    required this.bleController,
    required this.pollingService,
  });

  void start() {
    WidgetsBinding.instance.addObserver(this);
    print("🔁 Lifecycle observer startet");
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    print("🛑 Lifecycle observer stoppet");
  }

  void updateDevice({
    required DiscoveredDevice device,
    required String patientId, // ✅
  }) {
    _lastDevice = device;
    _lastPatientId = patientId;
    print("💾 Husker BLE-enhed: ${device.name} (${device.id}), patientId: $patientId");
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("📱 App resumed");
      if (_lastDevice != null && _lastPatientId != null) {
        print('🔄 Forsøger at reconnecte til tidligere BLE-enhed...');
        bleController.connectToDevice(
          device: _lastDevice!,
          patientId: _lastPatientId!,
        );
      }
    }
  }
}
