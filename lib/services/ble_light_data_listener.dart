import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class BleLightDataListener {
  final QualifiedCharacteristic lightCharacteristic;
  final FlutterReactiveBle ble;

  StreamSubscription<List<int>>? _subscription;
  Timer? _readTimer;

  BleLightDataListener({
    required this.lightCharacteristic,
    required this.ble,
  });

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

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _readTimer?.cancel();
    _readTimer = null;
    print("🔕 Stopper BLE notify/polling-lytning");
  }

  double calculateExposureScore(double melanopic, DateTime now) {
    final hour = now.hour + now.minute / 60.0;
    if (hour >= 7 && hour < 19) {
      return (melanopic / 250).clamp(0.0, 1.0) * 100;
    } else if (hour >= 19 && hour < 23) {
      return (10 / (melanopic > 0 ? melanopic : 0.01)).clamp(0.0, 1.0) * 100;
    } else {
      return (1 / (melanopic > 0 ? melanopic : 0.01)).clamp(0.0, 1.0) * 100;
    }
  }

  String getActionRequired(double melanopic, DateTime now) {
    final hour = now.hour + now.minute / 60.0;

    if (hour >= 7 && hour < 19) {
      if (melanopic < 250) return "increase";
      return "none";
    } else if (hour >= 19 && hour < 23) {
      if (melanopic > 10) return "decrease";
      return "none";
    } else {
      if (melanopic > 1) return "decrease";
      return "none";
    }
  }

  String lightTypeFromCode(int code) {
    switch (code) {
      case 0: return "Daylight";
      case 1: return "LED";
      case 2: return "Mixed";
      case 3: return "Halogen";
      case 4: return "Fluorescent";
      case 5: return "Fluorescent daylight";
      case 6: return "Screen";
      default: return "Unknown";
    }
  }

  Future<void> _handleData(List<int> data) async {
    if (data.isEmpty || data.length < 48) {
      print("⚠️ Tom eller forkert størrelse på data – ignoreres.");
      return;
    }

    try {
      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      final values = List.generate(12, (i) => byteData.getInt32(i * 4, Endian.little));
      final now = DateTime.now();
      final nowString = now.toIso8601String();

      final melanopic = values[1].toDouble();
      final exposureScore = calculateExposureScore(melanopic, now);
      final actionRequired = getActionRequired(melanopic, now);
      final lightType = lightTypeFromCode(values[5]);

      print("📊 Decode → ${values.map((v) => v.toString()).join(', ')}");
      print("📈 Exposure: ${exposureScore.toStringAsFixed(1)}%, action: $actionRequired, light_type: $lightType");

      final jwt = await AuthStorage.getToken();
      final patientId = await AuthStorage.getUserId();

      if (jwt == null || patientId == null) {
        LocalLogService.log("❌ JWT eller patient-ID mangler – kan ikke sende data");
        return;
      }

      final deviceSerial = lightCharacteristic.characteristicId.toString();

      // Registrér sensor automatisk
      final sensorId = await ApiService.registerSensorUse(
        patientId: patientId,
        deviceSerial: deviceSerial,
        jwt: jwt,
      );

      if (sensorId == null) {
        LocalLogService.log("❌ Kunne ikke registrere sensor – måling afbrudt.");
        return;
      }

      await OfflineStorageService.saveLocally(
        type: 'light_sample',
        data: {
          "timestamp": nowString,
          "values": values,
          "patient_id": patientId,
          "sensor_id": sensorId,
          "exposure_score": exposureScore,
          "action_required": actionRequired,
        },
      );

      final lightData = {
        "patient_id": patientId,
        "sensor_id": sensorId,
        "captured_at": nowString,
        "lux_level": values[0],
        "melanopic_edi": values[1],
        "der": values[2],
        "illuminance": values[3],
        "spectrum": values.sublist(4),
        "light_type": lightType,
        "exposure_score": exposureScore,
        "action_required": actionRequired == "increase" ? 1 : actionRequired == "decrease" ? 2 : 0,
      };

      final success = await ApiService.sendLightData(lightData, jwt);
      if (!success) {
        LocalLogService.log("⚠️ Data blev ikke sendt til API – beholdt lokalt.");
      }
    } catch (e) {
      print("❌ Fejl i håndtering af BLE-data: $e");
      LocalLogService.log("⚠️ Fejl ved parsing eller upload: $e");
    }
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
}
