import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';

import 'battery_service.dart';

class BatteryPollingService {
  final FlutterReactiveBle ble;
  final String deviceId;
  Timer? _timer;

  BatteryPollingService({
    required this.ble,
    required this.deviceId,
  });

  /// Starter polling: første læsning efter 20s, derefter hvert 5. minut.
  Future<void> start() async {
    // Første upload efter 20 sekunder
    Future.delayed(const Duration(seconds: 20), _readAndProcess);

    // Herefter hvert 5. minut
    _timer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _readAndProcess(),
    );
  }

  /// Stop polling
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Læs batteri-char, gem lokalt og send til backend (eller gem offline hvis fejler)
  Future<void> _readAndProcess() async {
    try {
      final char = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('180F'),
        characteristicId: Uuid.parse('2A19'),
      );
      final data = await ble.readCharacteristic(char);
      final level = data.isNotEmpty ? data[0] : 0;
      print("🔋 [BatteryPollingService] Læser batteri: $level%");

      // Gem offline-kø
      final jwt = await AuthStorage.getToken();
      final patientId = await AuthStorage.getUserId();
      if (jwt == null || patientId == null) {
        print("❌ Mangler JWT eller patientId – gemmer alligevel lokalt");
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

      // Registrér sensor for at få sensor_id
      final sensorId = await ApiService.registerSensorUse(
        patientId: patientId,
        deviceSerial: deviceId,
        jwt: jwt,
      );
      if (sensorId == null) {
        print("❌ Sensor-registrering mislykkedes – gemmer offline");
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

      // Forsøg at poste til backend
      final success = await BatteryService.sendToBackend(
        patientId: patientId,
        sensorId: sensorId,
        batteryLevel: level,
        jwt: jwt,
      );

      if (!success) {
        // hvis posten fejlede, så gem lokalt
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
      print("⚠️ Batteri-polling fejl: $e");
      await RemoteErrorLogger.log(
        patientId: await AuthStorage.getUserId() ?? 'unknown',
        type: 'battery',
        message: e.toString(),
        stack: st.toString(),
      );
    }
  }
}
