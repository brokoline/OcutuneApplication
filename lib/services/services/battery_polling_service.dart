import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/battery_service.dart';

import '../../controller/ble_controller.dart';

class BatteryPollingService {
  final FlutterReactiveBle ble;
  final String deviceId;
  Timer? _timer;

  BatteryPollingService({required this.ble, required this.deviceId});

  /// Starter polling: første send efter 20s, derefter hvert 5. minut
  Future<void> start() async {
    // Første upload efter 20 sekunder
    Future.delayed(const Duration(seconds: 20), _readAndSend);

    // Herefter hvert 5. minut
    _timer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _readAndSend(),
    );
  }

  /// Stop polling
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Public: tvinger med det samme en oplæsning og upload
  Future<void> readAndSend() async {
    await _readAndSend();
  }

  // --------------------------------------------------
  // Alt under her er uændret
  // --------------------------------------------------

  Future<void> _readAndSend() async {
    try {
      final char = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('180F'),
        characteristicId: Uuid.parse('2A19'),
      );
      final data = await ble.readCharacteristic(char);
      final level = data.isNotEmpty ? data[0] : 0;
      BleController.batteryNotifier.value = level;

      print("🔋 [BatteryPollingService] Læser batteri: $level%");
      await BatteryService.sendToBackend(batteryLevel: level);
    } catch (e) {
      print("⚠️ Batteri-polling fejl: $e");
    }
  }
}
