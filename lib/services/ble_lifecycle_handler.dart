import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';

class BleLifecycleHandler extends WidgetsBindingObserver {
  final BleController bleController;

  DiscoveredDevice? _lastDevice;
  String? _lastPatientId;

  BleLifecycleHandler({ required this.bleController });

  /// Start lytning på app-lifecycle
  void start() {
    WidgetsBinding.instance.addObserver(this);
    print("🔁 Lifecycle observer startet");
  }

  /// Stop lytning
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    print("🛑 Lifecycle observer stoppet");
  }

  // Husk hvilken enhed og patientId, vi skal reconnecte til
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
      // Når app’en går i baggrunden, bryd forbindelsen af—
      // BleController.disconnect() stopper samtidig polling‐services
        print("📱 App paused → afbryder BLE-forbindelse");
        bleController.disconnect();
        break;

      case AppLifecycleState.resumed:
      // Når app’en genaktiveres, forsøg genopkobling
        print("📱 App resumed → forsøger genopkobling");
        if (_lastDevice != null && _lastPatientId != null) {
          bleController.connectToDevice(
            device:    _lastDevice!,
            patientId: _lastPatientId!,
          );
        }
        break;

      default:
      // Intet specielt for andre tilstande
        break;
    }
  }
}
