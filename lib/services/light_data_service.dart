import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';

class LightDataService {
  static Future<void> sendToBackend({
    required int patientId,
    int? sensorId,
    double? luxLevel,
    double? melanopicEdi,
    double? der,
    double? illuminance,
    List<double>? spectrum,
    String? lightType,
    double? exposureScore,
    bool actionRequired = false,
  }) async {
    final uri = Uri.parse('http://192.168.64.6:5000/light-data');

    final data = {
      "patient_id": patientId,
      "sensor_id": sensorId,
      "lux_level": luxLevel,
      "melanopic_edi": melanopicEdi,
      "der": der,
      "illuminance": illuminance,
      "spectrum": spectrum,
      "light_type": lightType,
      "exposure_score": exposureScore,
      "action_required": actionRequired,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 201) {
        throw Exception("Fejl i serverresponse");
      }
    } catch (e) {
      await OfflineStorageService.saveLocally(type: 'light', data: data);

      await RemoteErrorLogger.log(
        patientId: patientId,
        type: 'light',
        message: e.toString(),
      );
    }
  }
}
