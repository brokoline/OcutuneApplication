import 'dart:convert';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/battery_service.dart';
import 'package:ocutune_light_logger/services/services/patient_light_data_service.dart';
import 'package:ocutune_light_logger/services/remote_error_logger.dart';


class OfflineSyncManager {
  static Future<void> syncAll() async {
    final rows = await OfflineStorageService.getUnsyncedData();

    for (final row in rows) {
      final id = row['id'] as int;
      final type = row['type'] as String;
      final json = jsonDecode(row['json']);

      try {
        if (type == 'battery') {
          await BatteryService.sendToBackend(
            patientId: json['patient_id'],
            sensorId: json['sensor_id'],
            batteryLevel: json['battery_level'],
          );
        } else if (type == 'light') {
          await PatientLightDataService.sendToBackend(
            patientId: json['patient_id'],
            sensorId: json['sensor_id'],
            luxLevel: json['lux_level'],
            melanopicEdi: json['melanopic_edi'],
            der: json['der'],
            illuminance: json['illuminance'],
            spectrum: List<double>.from(json['spectrum']),
            lightType: json['light_type'],
            exposureScore: json['exposure_score'],
            actionRequired: json['action_required'],
          );
        }

        await OfflineStorageService.deleteById(id);
        print("✅ Synkroniseret: $type $id");
      } catch (e) {
        await RemoteErrorLogger.log(
          patientId: json['patient_id'],
          type: type,
          message: e.toString(),
        );
      }
    }
  }
}
