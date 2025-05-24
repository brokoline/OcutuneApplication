import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

import '../controller/ble_controller.dart';

class BatteryService {
  static DateTime? _lastSent;
  static const Duration minInterval = Duration(minutes: 10);

  static Future<void> sendToBackend({
    required int batteryLevel,
  }) async {
    final now = DateTime.now();

    if (batteryLevel <= 0) {
      print("⏱️ Batteriniveau er 0 eller ukendt – venter med upload.");
      return;
    }

    if (_lastSent != null && now.difference(_lastSent!) < minInterval) {
      print("⏱️ Springer batteri-upload over (for nylig sendt)");
      return;
    }

    try {
      final jwt = await AuthStorage.getToken();
      final patientId = await AuthStorage.getUserId();
      final deviceSerial = BleController.connectedDevice?.id ?? "unknown-device";

      if (jwt == null || patientId == null) {
        print("❌ JWT eller patientId mangler – sender ikke batteri");
        return;
      }

      final sensorId = await ApiService.registerSensorUse(
        patientId: patientId,
        deviceSerial: deviceSerial,
        jwt: jwt,
      );

      if (sensorId == null) {
        print("❌ Sensor-registrering mislykkedes – batteridata springes over");
        return;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/patient-battery-status');
      final payload = {
        "patient_id": patientId,
        "sensor_id": sensorId,
        "battery_level": batteryLevel,
      };

      print("📤 Batteri-upload til $uri");
      print("🧾 Payload: $payload");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        _lastSent = now;
        print("✅ Batteriniveau sendt");
      } else {
        throw Exception("Fejl i serverresponse: ${response.statusCode} ${response.body}");
      }

    } catch (e) {
      print("⚠️ Fejl i batteri-upload: $e");

      final patientId = await AuthStorage.getUserId();

      await OfflineStorageService.saveLocally(
        type: 'battery',
        data: {
          "patient_id": patientId,
          "battery_level": batteryLevel,
        },
      );

      if (patientId != null) {
        await RemoteErrorLogger.log(
          patientId: patientId,
          type: 'battery',
          message: e.toString(),
        );
      }
    }
  }
}
