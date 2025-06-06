// lib/services/sync_use_case.dart

import 'dart:convert';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart'; // <- Hent token herfra

/// SyncUseCase tager lokale, u‐synkroniserede rækker fra OfflineStorageService
/// og forsøger at sende dem til serveren via ApiService. Hvis en enkelt række
/// ikke kan synkroniseres, fanges fejlen pr. post, og vi prøver igen næste runde.
class SyncUseCase {
  /// Hent alle rækker, der ligger i den lokale SQLite‐tabel 'unsynced_data',
  /// og send dem til serveren. Hvis det lykkes, slettes den pågældende række.
  static Future<void> syncAll() async {
    // Hent alle usynkroniserede rækker
    final rows = await OfflineStorageService.getUnsyncedData();

    if (rows.isEmpty) {
      print("[SyncUseCase] Ingen offline‐poster at synkronisere.");
      return;
    }

    print("[SyncUseCase] Starter synkronisering af ${rows.length} offline‐poster...");

    // Loop over hver række fra unsynced_data
    for (final row in rows) {
      final int id = row['id'] as int;
      final String type = row['type'] as String;
      final Map<String, dynamic> payload = jsonDecode(row['json'] as String);

      try {
        // -------------------------------------------------------
        // 1) Batteri‐data (hvis du har gemt 'type':'battery')
        // -------------------------------------------------------
        if (type == 'battery') {
          final String patientId = payload['patient_id'] as String;
          final int batteryLevel = payload['battery_level'] as int;

          // Tjek om payload['sensor_id'] enten er en int eller streng, parse til int?
          int? sensorId;
          if (payload['sensor_id'] is int) {
            sensorId = payload['sensor_id'] as int;
          } else if (payload['sensor_id'] is String) {
            sensorId = int.tryParse(payload['sensor_id'] as String);
          }

          print("[SyncUseCase] Forsøger at sende battery id=$id til server…");

          // Kald ApiService.reportBatteryStatus
          final bool success = await ApiService.reportBatteryStatus(
            patientId,
            batteryLevel,
            sensorId: sensorId,
          );

          if (success) {
            await OfflineStorageService.deleteById(id);
            print("[SyncUseCase] Slettede battery‐post id=$id fra offline‐kø.");
          } else {
            print("[SyncUseCase] reportBatteryStatus returnerede false for id=$id. Beholder posten.");
          }
        }
        // -------------------------------------------------------
        // 2) Lysdata (hvis du har gemt 'type':'light')
        // -------------------------------------------------------
        else if (type == 'light') {
          print("[SyncUseCase] Forsøger at sende light id=$id til server…");

          // Hent JWT fra AuthStorage
          final String? jwt = await AuthStorage.getToken();
          if (jwt == null) {
            print("[SyncUseCase] Ingen JWT tilgængelig – kan ikke kalde sendLightData");
            // Vi springer selve kaldet over, men sletter ikke posten – så der kan forsøges næste gang.
            continue;
          }

          // ApiService.sendLightData forventer (Map<String,dynamic> data, String jwt)
          final bool success = await ApiService.sendLightData(
            payload,
            jwt,
          );

          if (success) {
            await OfflineStorageService.deleteById(id);
            print("[SyncUseCase] Slettede light‐post id=$id fra offline‐kø.");
          } else {
            print("[SyncUseCase] sendLightData returnerede false for id=$id. Beholder posten.");
          }
        }
        // -------------------------------------------------------
        // 3) Ukendt type → slet posten for at undgå at sidde fast
        // -------------------------------------------------------
        else {
          print("[SyncUseCase] Ukendt type '$type' for id=$id; sletter for at undgå loop.");
          await OfflineStorageService.deleteById(id);
        }
      }
      catch (e) {
        // Fanger exception per post (fx netværkstimeout, server‐fejl, JSON‐fejl osv.)
        print("[SyncUseCase] FEJL under synkronisering af id=$id, type='$type': $e");
        // Vi sletter ikke posten her, så den bliver forsøgt igen næste runde.
      }
    }

    print("[SyncUseCase] Synkroniseringsrunde færdig.");
  }
}
