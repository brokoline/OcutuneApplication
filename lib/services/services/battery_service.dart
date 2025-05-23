import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

import '../controller/ble_controller.dart';

class BatteryService {
  static Future<void> sendToBackend({
    required int batteryLevel,
  }) async {
    try {
      final jwt = await AuthStorage.getToken();
      final patientId = await AuthStorage.getUserId();
      final deviceSerial = BleController.connectedDevice?.id ?? "unknown-device";

      if (jwt == null || patientId == null) {
        throw Exception("JWT eller bruger-id mangler");
      }

      final sensorId = await ApiService.registerSensorUse(
        patientId: patientId,
        deviceSerial: deviceSerial,
        jwt: jwt,
      );

      final uri = Uri.parse('http://192.168.64.6:5000/patient-battery-status');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          "patient_id": patientId,
          "sensor_id": sensorId,
          "battery_level": batteryLevel,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception("Fejl i serverresponse: ${response.body}");
      }

      print("✅ Batteriniveau sendt");
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
