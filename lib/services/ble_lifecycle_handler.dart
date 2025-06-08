import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';

class BleLifecycleHandler extends WidgetsBindingObserver {
  final BleController bleController;

  DiscoveredDevice? _lastDevice;
  String? _lastPatientId;

  BleLifecycleHandler({ required this.bleController });

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
    required String patientId,
  }) {
    _lastDevice    = device;
    _lastPatientId = patientId;
    print("💾 Husker BLE-enhed: ${device.name} (${device.id}), patientId: $patientId");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
              print("📱 App paused → afbryder BLE-forbindelse");
        bleController.disconnect();
        break;

      case AppLifecycleState.resumed:
        print("📱 App resumed → forsøger genopkobling");
        if (_lastDevice != null && _lastPatientId != null) {
          bleController.connectToDevice(
            device:    _lastDevice!,
            patientId: _lastPatientId!,
          );
        }
        break;

      default:
        break;
    }
  }
}
