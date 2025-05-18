import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/patient_light_data_service.dart';
import 'package:ocutune_light_logger/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/local_log_service.dart';

import 'ble_controller.dart';

class BleLightDataListener {
  final QualifiedCharacteristic lightCharacteristic;
  final FlutterReactiveBle ble;
  final int patientId;
  final int sensorId;

  StreamSubscription<List<int>>? _subscription;

  BleLightDataListener({
    required this.lightCharacteristic,
    required this.ble,
    required this.patientId,
    required this.sensorId,
  });

  void startListening() {
    print("🎧 Starter BLE notify-lytning på: ${lightCharacteristic.characteristicId}");

    _subscription = ble.subscribeToCharacteristic(lightCharacteristic).listen(
          (data) async {
        print("📦 Rådata modtaget: $data (length: ${data.length})");

        if (data.isEmpty) {
          print("⚠️ Data var tom, ignoreres.");
          return;
        }

        try {
          if (data.length < 16) {
            print("⚠️ Modtaget data er for kort (<16 bytes), mulig fejl i sensor eller format.");
            return;
          }

          final byteData = ByteData.sublistView(Uint8List.fromList(data));
          final lux = byteData.getFloat32(0, Endian.little);
          final melanopicEdi = byteData.getFloat32(4, Endian.little);
          final der = byteData.getFloat32(8, Endian.little);
          final illuminance = byteData.getFloat32(12, Endian.little);
          final now = DateTime.now().toIso8601String();

          print("📊 Decode → Lux: $lux, EDI: $melanopicEdi, DER: $der, Illu: $illuminance");
          BleController.latestLightData.value = {
            "lux": lux,
            "edi": melanopicEdi,
            "der": der,
            "illu": illuminance,
          };


          await PatientLightDataService.sendToBackend(
            patientId: patientId,
            sensorId: sensorId,
            luxLevel: lux,
            melanopicEdi: melanopicEdi,
            der: der,
            illuminance: illuminance,
            spectrum: [], // kan udfyldes senere
            lightType: 'LED',
            exposureScore: 80.0,
            actionRequired: false,
          );

          LocalLogService.log('✅ Lysdata gemt @ $now: $lux lux');
        } catch (e) {
          print("❌ Fejl under behandling af notify-data: $e");

          await OfflineStorageService.saveLocally(
            type: 'light',
            data: {
              "patient_id": patientId,
              "sensor_id": sensorId,
              "lux_level": null,
              "melanopic_edi": null,
              "der": null,
              "illuminance": null,
              "spectrum": [],
              "light_type": "LED",
              "exposure_score": 0,
              "action_required": false,
            },
          );

          LocalLogService.log('⚠️ Gemt offline pga. fejl: $e');
        }
      },
      onError: (e) {
        print("❌ Notify stream-fejl: $e");
        LocalLogService.log('❌ BLE notify-fejl: $e');
      },
    );
  }

  Future<void> testReadOnce() async {
    try {
      print("🧪 Læser én gang fra karakteristik manuelt...");
      final result = await ble.readCharacteristic(lightCharacteristic);
      print("🧾 Manuel læsning: $result");
    } catch (e) {
      print("❌ Fejl ved manuel læsning: $e");
    }
  }


  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    print("🔕 Stopper BLE notify-lytning");
  }
}
