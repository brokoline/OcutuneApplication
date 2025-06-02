import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/services/remote_error_logger.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/battery_service.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';

class SyncUseCase {
  static Future<void> syncAll() async {
    // 1) Purge: slet alt, der har "sensor_id": -1 eller "sensor_id": null
    await OfflineStorageService.deleteInvalidSensorData();

    // 2) Hent resten af rækkerne
    final rows = await OfflineStorageService.getUnsyncedData();

    for (final row in rows) {
      final int    id   = row['id'] as int;
      final String type = row['type'] as String;
      final Map<String, dynamic> json = jsonDecode(row['json']);

      try {
        if (type == 'battery') {
          // Bemærk: hvis dine “battery”-poster også indeholder sensor_id,
          // kan du evt. tilføje en tilsvarende purge check her.
          await BatteryService.sendToBackend(
            batteryLevel: json['battery_level'],
          );
        } else if (type == 'light') {
          final uri = Uri.parse('${ApiService.baseUrl}/api/sensor/patient-light-data');

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

        // 3) Hvis vi når hertil uden fejl, slet posten lokalt
        await OfflineStorageService.deleteById(id);
        final now = DateTime.now().toIso8601String();
        print("✅ [$now] Synkroniseret: $type $id");

      } catch (e) {
        // 4) Ved fejl: log til din “remote error logger” og slet posten
        print("❌ Fejl ved synkronisering af $type $id: $e");

        await RemoteErrorLogger.log(
          patientId: json['patient_id'] ?? -1,
          type: type,
          message: e.toString(),
        );

        // Her sletter vi alligevel posten, fordi vi regner med
        // at “fejl i sensor_id” aldrig vil rette sig.
        //
        // Hvis du vil beholde andre typer fejl (fx midlertidige netværksfejl),
        // kan du i stedet checke e.toString() og kun slette, hvis det er 'invalid sensor_id'.
        await OfflineStorageService.deleteById(id);
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
