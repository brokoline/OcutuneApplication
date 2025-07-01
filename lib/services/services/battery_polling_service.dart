import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';

import 'battery_service.dart';

class BatteryPollingService {
  final FlutterReactiveBle ble;
  final String deviceId;
  final String sensorId;

  Timer? _timer;
  final StreamController<int> _batteryController = StreamController<int>.broadcast();
  Stream<int> get batteryStream => _batteryController.stream;

  BatteryPollingService({
    required this.ble,
    required this.deviceId,
    required this.sensorId,
  });

  // Starter polling: første læsning efter 15s, derefter hvert 5. minut.
  Future<void> start() async {
    // Første upload efter 15 sekunder
    Future.delayed(const Duration(seconds: 15), () async {
      await _readAndProcess();

      // Herefter hvert 5. minut
      _timer = Timer.periodic(
        const Duration(minutes: 5),
            (_) => _readAndProcess(),
      );
    });
  }

  Future<void> _readAndProcess() async {
    try {
      final char = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('180F'),
        characteristicId: Uuid.parse('2A19'),
      );
      final data = await ble.readCharacteristic(char);
      final level = data.isNotEmpty ? data[0] : 0;

      _batteryController.add(level);
      print("[BatteryPollingService] Læser batteri: $level%");

      final jwt = await AuthStorage.getToken();
      final patientId = await AuthStorage.getUserId();
      if (jwt == null || patientId == null) {
        print("Mangler JWT eller patientId – gemmer alligevel lokalt");
        await OfflineStorageService.saveLocally(
          type: 'battery',
          data: {
            'patient_id': patientId,
            'device_serial': deviceId,
            'battery_level': level,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        return;
      }

      // Send til backend
      final success = await BatteryService.sendToBackend(
        patientId: patientId,
        sensorId: sensorId,
        batteryLevel: level,
        jwt: jwt,
      );

      if (!success) {
        await OfflineStorageService.saveLocally(
          type: 'battery',
          data: {
            'patient_id': patientId,
            'sensor_id': sensorId,
            'battery_level': level,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e, st) {
      print("Batteri-polling fejl: $e");
      await RemoteErrorLogger.log(
        patientId: await AuthStorage.getUserId() ?? 'unknown',
        type: 'battery',
        message: e.toString(),
        stack: st.toString(),
      );
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _batteryController.close();
  }
}
