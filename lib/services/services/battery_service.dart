import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/api_services.dart';

class BatteryService {
  static DateTime? _lastSent;
  static const Duration _minInterval = Duration(minutes: 5);

  /// Poster batteri til backend. Returnerer true ved succes eller hvis vi throttler.
  static Future<bool> sendToBackend({
    required String patientId,
    required String sensorId,
    required int batteryLevel,
    required String jwt,
  }) async {
    final now = DateTime.now();

    // drop 0 eller negative værdier
    if (batteryLevel <= 0) {
      print("⏱️ Springer batteri-upload over (level <= 0)");
      return false;
    }

    // Throttling
    if (_lastSent != null && now.difference(_lastSent!) < _minInterval) {
      print("⏱️ Springer batteri-upload over (throttling)");
      return true;
    }

    final uri = Uri.parse("${ApiService.baseUrl}/api/sensor/patient-battery-status");
    final body = {
      'patient_id': patientId,
      'sensor_id': sensorId,
      'battery_level': batteryLevel,
    };

    print("📤 Batteri-upload til $uri");
    print("🧾 Payload: $body");

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      _lastSent = now;
      print("✅ Batteriniveau sendt");
      return true;
    }

    print("❌ Fejl ved batteri-API: ${resp.statusCode} ${resp.body}");
    return false;
  }
}
