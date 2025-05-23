import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';

class BatteryService {
  static Future<void> sendToBackend({
    required int patientId,
    int? sensorId,
    required int batteryLevel,
  }) async {
    final uri = Uri.parse('http://192.168.64.6:5000/battery-status');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "patient_id": patientId,
          "sensor_id": sensorId,
          "battery_level": batteryLevel,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception("Fejl i serverresponse");
      }
    } catch (e) {
      await OfflineStorageService.saveLocally(
        type: 'battery',
        data: {
          "patient_id": patientId,
          "sensor_id": sensorId,
          "battery_level": batteryLevel,
        },
      );

      await RemoteErrorLogger.log(
        patientId: patientId,
        type: 'battery',
        message: e.toString(),
      );
    }
  }
}
