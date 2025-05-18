import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/ble_controller.dart';

class BleLifecycleHandler extends WidgetsBindingObserver {
  final BleController bleController;

  DiscoveredDevice? _lastDevice;
  int? _lastPatientId;

  BleLifecycleHandler({required this.bleController});

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
    required int patientId,
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
      } else {
        print("⚠️ Ingen tidligere BLE-enhed gemt – reconnect springes over");
      }
    }
  }
}
