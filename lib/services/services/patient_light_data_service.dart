import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';

class PatientLightDataService {
  static Future<void> sendToBackend({
    required int patientId,
    required int sensorId,
    required double luxLevel,
    required double melanopicEdi,
    required double der,
    required double illuminance,
    required List<double> spectrum,
    required String lightType,
    required double exposureScore,
    required bool actionRequired,
  }) async {
    final uri = Uri.parse('http://192.168.64.6:5000/patient-light-data');

    final data = {
      "patient_id": patientId,
      "sensor_id": sensorId,
      "lux_level": luxLevel,
      "captured_at": DateTime.now().toIso8601String(),
      "melanopic_edi": melanopicEdi,
      "der": der,
      "illuminance": illuminance,
      "spectrum": spectrum,
      "light_type": lightType,
      "exposure_score": exposureScore,
      "action_required": actionRequired,
    };

    try {
      // 🔍 Debug-log for at bekræfte kald og payload
      print("📤 Sender lysdata til backend:");
      print(jsonEncode(data));
      print("➡️ POST til: $uri");

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // 📥 Backend-respons log
      print("📥 Responskode: ${response.statusCode}");
      print("📥 Responsbody: ${response.body}");

      if (response.statusCode != 201) {
        throw Exception("Fejl i serverresponse: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Fejl ved upload af lysdata: $e");

      await OfflineStorageService.saveLocally(type: 'light', data: data);
      await RemoteErrorLogger.log(
        patientId: patientId,
        type: 'light',
        message: e.toString(),
      );
    }
  }
}
