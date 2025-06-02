// lib/services/sync_use_case.dart

import 'dart:convert';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';

/// SyncUseCase tager lokale, u‐synkroniserede rækker fra OfflineStorageService
/// og forsøger at sende dem til serveren via ApiService. Hvis en enkelt række
/// ikke kan synkroniseres, fanges fejlen per‐post, og vi prøver igen næste runde.
class SyncUseCase {
  /// Hent alle rækker, der ligger i den lokale SQLite‐tabel 'unsynced_data',
  /// og send dem til serveren. Hvis det lykkes, slettes den pågældende række.
  static Future<void> syncAll() async {
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
        if (type == 'battery') {
          // Eksempel: batteri‐type
          final String patientId = payload['patient_id'] as String;
          final int batteryLevel = payload['battery_level'] as int;
          final int? sensorId = (payload['sensor_id'] is int)
              ? payload['sensor_id'] as int
              : int.tryParse(payload['sensor_id'].toString());

          print("[SyncUseCase] Forsøger at sende battery id=$id til server…");

          final bool success = await ApiService.reportBatteryStatus(
            patientId,
            batteryLevel,
            sensorId: sensorId,
          );

          if (success) {
            await OfflineStorageService.deleteById(id);
            print("[SyncUseCase] Slettede battery‐post id=$id fra offline‐kø.");
          } else {
            print("[SyncUseCase] reportBatteryStatus returnerede false for id=$id, beholder posten.");
          }
        } else if (type == 'light') {
          // Eksempel: lysdata‐type
          print("[SyncUseCase] Forsøger at sende light id=$id til server…");

          // sendLightData forventer to argumenter: data‐map og jwt‐token (hvis du bruger token)
          // Hvis ApiService.sendLightData kræver JWT, hent det først: final jwt = await AuthStorage.getToken();
          final String? jwt = await ApiService.getToken(); // eller AuthStorage.getToken() alt efter din implementering

          final bool success = await ApiService.sendLightData(
            payload,
            jwt ?? '',
          );

          if (success) {
            await OfflineStorageService.deleteById(id);
            print("[SyncUseCase] Slettede light‐post id=$id fra offline‐kø.");
          } else {
            print("[SyncUseCase] sendLightData returnerede false for id=$id, beholder posten.");
          }
        } else {
          print("[SyncUseCase] Ukendt type '$type' for id=$id; sletter alligevel for at undgå endeløs loop.");
          await OfflineStorageService.deleteById(id);
        }
      } catch (e) {
        // Fanger exception pr. post (fx netværkstimeout, server‐fejl, JSON‐fejl osv.)
        print("[SyncUseCase] FEJL under synkronisering af id=$id, type='$type': $e");
        // Vi vælger ikke at slette posten her, så den bliver forsøgt igen næste runde.
      }
    }

    print("[SyncUseCase] Synkroniseringsrunde færdig.");
  }
}
