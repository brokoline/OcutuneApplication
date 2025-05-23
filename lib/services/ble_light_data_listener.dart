import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/patient_light_data_service.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';

class BleLightDataListener {
  final QualifiedCharacteristic lightCharacteristic;
  final FlutterReactiveBle ble;
  final int patientId;
  final int sensorId;

  StreamSubscription<List<int>>? _subscription;
  Timer? _readTimer;

  BleLightDataListener({
    required this.lightCharacteristic,
    required this.ble,
    required this.patientId,
    required this.sensorId,
  });

  /// Notify-baseret lytning (BLE notify characteristic)
  void startListening() {
    print("🎧 Starter BLE notify-lytning på: ${lightCharacteristic.characteristicId}");

    _subscription = ble.subscribeToCharacteristic(lightCharacteristic).listen(
          (data) async {
        print("📦 Notify-data modtaget: $data (length: ${data.length})");
        await _handleData(data);
      },
      onError: (e) {
        print("❌ Notify stream-fejl: $e");
        LocalLogService.log('❌ BLE notify-fejl: $e');
      },
    );
  }

  /// Fallback-løsning: Læsning hver 10. sekund med timer
  void startPollingReads() {
    print("📆 Starter polling-læsning hver 10. sekund fra ${lightCharacteristic.characteristicId}");

    _readTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final result = await ble.readCharacteristic(lightCharacteristic);
        print("🧾 Manuel læsning (poll): $result");
        await _handleData(result);
      } catch (e) {
        print("❌ Fejl under polling-læsning: $e");
      }
    });
  }

  /// Stopper både notify og polling
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _readTimer?.cancel();
    _readTimer = null;
    print("🔕 Stopper BLE notify/polling-lytning");
  }

  /// Håndtering og parsing af byte-data
  Future<void> _handleData(List<int> data) async {
    if (data.isEmpty) {
      print("⚠️ Data var tom, ignoreres.");
      return;
    }

    if (data.length < 48) {
      print("⚠️ Forventede 48 bytes, fik kun ${data.length} – ignoreres.");
      return;
    }

    try {
      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      final values = List.generate(12, (i) => byteData.getInt32(i * 4, Endian.little));
      final now = DateTime.now().toIso8601String();

      print("📊 Decode → ${values.map((v) => v.toString()).join(', ')}");

      await OfflineStorageService.saveLocally(
        type: 'light_sample',
        data: {
          "timestamp": now,
          "values": values,
          "patient_id": patientId,
          "sensor_id": sensorId,
        },
      );

      LocalLogService.log('✅ Parsed sample @ $now → $values');
    } catch (e) {
      print("❌ Fejl under behandling af int32-pakke: $e");
      LocalLogService.log('⚠️ Gemt fejl ved parsing: $e');
    }
  }

  /// Til manuel test af karakteristik
  Future<void> testReadOnce() async {
    try {
      print("🧪 Læser én gang fra karakteristik manuelt...");
      final result = await ble.readCharacteristic(lightCharacteristic);
      print("🧾 Manuel læsning: $result");
    } catch (e) {
      print("❌ Fejl ved manuel læsning: $e");
    }
  }
}
