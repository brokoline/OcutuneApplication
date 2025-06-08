import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

import 'package:ocutune_light_logger/controller/ble_controller.dart';

class BatteryService {
  static DateTime? _lastSent;
  static const Duration minInterval = Duration(minutes: 5);

  /// Sender et batteriniveau til backend (eller gemmer lokalt ved fejl).
  /// Returnerer `true` hvis den blev sendt eller skippet pga. throttling.
  static Future<bool> sendToBackend({
    required int batteryLevel,
    bool returnSuccess = false,
  }) async {
    final now = DateTime.now();

    // Hvis niveauet er 0 eller uoplyst, så drop det
    if (batteryLevel <= 0) {
      print("⏱️ Springer batteri-upload over (for nylig sendt)");
      print("⏱️ Batteriniveau er 0 eller ukendt – venter med upload.");
      return false;
    }

    // Throttling: minInterval mellem uploads
    if (_lastSent != null && now.difference(_lastSent!) < minInterval) {
      print("⏱️ Springer batteri-upload over (for nylig sendt)");
      return true;
    }

    try {
      // Hent auth-token og patient‐ID
      final jwt = await AuthStorage.getToken();
      final rawId = await AuthStorage.getUserId();
      final patientId = rawId?.toString();

  // Brug den aktuelle enheds-id fra notifikatoren
      final deviceSerial = BleController.connectedDeviceNotifier.value?.id ?? 'unknown-device';

      if (jwt == null || patientId == null) {
        print("❌ JWT eller patientId mangler – sender ikke batteri");
        return false;
      }


      // Registrér sensoren (får sensor_id)
      final sensorId = await ApiService.registerSensorUse(
        patientId: patientId,
        deviceSerial: deviceSerial,
        jwt: jwt,
      );
      if (sensorId == null) {
        print("❌ Sensor-registrering mislykkedes – batteridata springes over");
        return false;
      }

      // Byg request
      final uri = Uri.parse('${ApiService.baseUrl}/api/sensor/patient-battery-status');
      final payload = {
        "patient_id": patientId,
        "sensor_id": sensorId,
        "battery_level": batteryLevel,
      };

      print("📤 Batteri-upload til $uri");
      print("🧾 Payload: $payload");

      // POST til API
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _lastSent = now;
        print("✅ Batteriniveau sendt");
        return true;
      } else {
        throw Exception("Fejl i serverresponse: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      // Ved fejl: gem offline og log
      print("⚠️ Fejl i batteri-upload: $e");

      final rawId = await AuthStorage.getUserId();
      final patientId = rawId?.toString();

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
      return false;
    }
  }
}
