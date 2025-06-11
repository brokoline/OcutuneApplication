// lib/services/sync_use_case.dart

import 'dart:convert';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class SyncUseCase {
  static bool _isSyncing = false;

  static Future<void> syncAll() async {
    if (_isSyncing) {
      print('[SyncUseCase] Sync already in progress, skipping overlapping call.');
      return;
    }
    _isSyncing = true;
    try {
      await OfflineStorageService.purgeInvalidUnsyncedData();
      final rows = await OfflineStorageService.getUnsyncedData();
      if (rows.isEmpty) {
        print('[SyncUseCase] Ingen offline‑poster at synkronisere.');
        return;
      }
      print('[SyncUseCase] Starter synkronisering af ${rows.length} offline‑poster...');

      for (final row in rows) {
        final int id = row['id'] as int;
        final String type = row['type'] as String;
        final Map<String, dynamic> payload =
        jsonDecode(row['json'] as String) as Map<String, dynamic>;

        try {
          if (type == 'battery') {
            print('[SyncUseCase] Forsøger at sende battery id=$id til server…');
            final String patientId = payload['patient_id'] as String;
            final int batteryLevel = payload['battery_level'] as int;
            int? sensorId;
            if (payload['sensor_id'] is int) {
              sensorId = payload['sensor_id'] as int;
            } else if (payload['sensor_id'] is String) {
              sensorId = int.tryParse(payload['sensor_id'] as String);
            }

            final bool success = await ApiService.reportBatteryStatus(
              patientId,
              batteryLevel,
              sensorId: sensorId,
            );
            if (success) {
              await OfflineStorageService.deleteById(id);
              print('[SyncUseCase] Slettede battery‑post id=$id fra offline‑kø.');
            } else {
              print('[SyncUseCase] reportBatteryStatus returnerede false for id=$id. Beholder posten.');
            }
          } else if (type == 'light') {
            print('[SyncUseCase] Forsøger at sende light id=$id til server…');

            // ─── 1) Pre‑valider payload for null/forkerte værdier ────
            const requiredFields = [
              'patient_id',
              'sensor_id',
              'timestamp',
              'lux_level',
              'melanopic_edi',
              'illuminance',
            ];
            final isBad = requiredFields.any((k) {
              final v = payload[k];
              if (v == null) return true;
              if (k == 'sensor_id' && (v is int ? false : int.tryParse(v.toString()) == null)) {
                return true;
              }
              return false;
            }) ||
                // Fjern “Unknown” som light_type
                (payload['light_type'] == null || payload['light_type'] == 'Unknown');

            if (isBad) {
              print('[SyncUseCase] Ugyldig light‑data id=$id (null/Unknown) – sletter posten.');
              await OfflineStorageService.deleteById(id);
              continue;
            }

            // ─── 2) Hent JWT og send ───
            final String? jwt = await AuthStorage.getToken();
            if (jwt == null) {
              print('[SyncUseCase] Ingen JWT tilgængelig – springer over id=$id');
              continue;
            }

            final bool success = await ApiService.sendLightData(payload, jwt);
            if (success) {
              await OfflineStorageService.deleteById(id);
              print('[SyncUseCase] Slettede light‑post id=$id fra offline‑kø.');
            } else {
              print('[SyncUseCase] sendLightData returnerede false for id=$id. Beholder posten.');
            }
          } else {
            print("[SyncUseCase] Ukendt type '$type' for id=$id; sletter posten.");
            await OfflineStorageService.deleteById(id);
          }
        } catch (e) {
          print("[SyncUseCase] FEJL under synkronisering af id=$id, type='$type': $e");
        }
      }

      print('[SyncUseCase] Synkroniseringsrunde færdig.');
    } finally {
      _isSyncing = false;
    }
  }
}
