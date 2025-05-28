import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/remote_error_logger.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/battery_service.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';

class SyncUseCase {
  static Future<void> syncAll() async {
    final rows = await OfflineStorageService.getUnsyncedData();

    for (final row in rows) {
      final id = row['id'] as int;
      final type = row['type'] as String;
      final json = jsonDecode(row['json']);

      try {
        if (type == 'battery') {
          await BatteryService.sendToBackend(
            batteryLevel: json['battery_level'],
          );
        } else if (type == 'light') {
          final uri = Uri.parse('${ApiService.baseUrl}/patient-light-data');

          final payload = {
            "patient_id": json['patient_id'],
            "sensor_id": json['sensor_id'],
            "lux_level": json['lux_level'],
            "captured_at": json['timestamp'],
            "melanopic_edi": json['melanopic_edi'],
            "der": json['der'],
            "illuminance": json['illuminance'],
            "spectrum": json['spectrum'],
            "light_type": lightTypeFromCode(json['light_type']),
            "exposure_score": json['exposure_score'],
            "action_required": json['action_required'],
          };

          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

          if (response.statusCode != 201) {
            throw Exception("⚠️ Fejl ved upload: ${response.statusCode} - ${response.body}");
          }
        }

        await OfflineStorageService.deleteById(id);
        final now = DateTime.now().toIso8601String();
        print("✅ [$now] Synkroniseret: $type $id");
      } catch (e) {
        print("❌ Fejl ved synkronisering af $type $id: $e");

        await RemoteErrorLogger.log(
          patientId: json['patient_id'] ?? -1,
          type: type,
          message: e.toString(),
        );
      }
    }
  }

  static String lightTypeFromCode(dynamic code) {
    switch (code) {
      case 0:
        return "Daylight";
      case 1:
        return "LED";
      case 2:
        return "Mixed";
      case 3:
        return "Halogen";
      case 4:
        return "Fluorescent";
      case 5:
        return "Fluorescent daylight";
      case 6:
        return "Screen";
      default:
        return "Unknown";
    }
  }
}
