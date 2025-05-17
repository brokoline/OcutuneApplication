import 'dart:convert';
import 'package:http/http.dart' as http;

class BatteryService {
  static Future<void> sendToBackend({
    required int patientId,
    int? sensorId,
    required int batteryLevel,
  }) async {
    final uri = Uri.parse('http://192.168.64.6:5000/battery-status');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "patient_id": patientId,
        "sensor_id": sensorId,
        "battery_level": batteryLevel,
      }),
    );

    if (response.statusCode == 201) {
      print("✅ Batteri-data sendt");
    } else {
      print("❌ FEJL: ${response.body}");
    }
  }
}
