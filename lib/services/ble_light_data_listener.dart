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

  Timer? _readTimer;
  bool _isReading = false;
  int? _patientId;
  String? _jwt;
  int? _sensorId;

  BleLightDataListener({
    required this.lightCharacteristic,
    required this.ble,
  });

  void startPollingReads({Duration interval = const Duration(seconds: 10)}) async {
    print("📆 Starter polling-læsning hver ${interval.inSeconds} sek. fra ${lightCharacteristic.characteristicId}");

    if (_readTimer?.isActive ?? false) {
      print("⛔️ Allerede aktiv polling – annullerer nyt startforsøg.");
      return;
    }

    // Hent login og sensor-oplysninger én gang
    _jwt = await AuthStorage.getToken();
    _patientId = await AuthStorage.getUserId();
    if (_jwt == null || _patientId == null) {
      LocalLogService.log("❌ JWT eller patient-ID mangler – kan ikke starte polling");
      return;
    }

    _sensorId = await ApiService.registerSensorUse(
      patientId: _patientId!,
      deviceSerial: lightCharacteristic.characteristicId.toString(),
      jwt: _jwt!,
    );

    if (_sensorId == null) {
      LocalLogService.log("❌ Kunne ikke registrere sensor – polling afbrudt.");
      return;
    }

    _readTimer?.cancel();
    _readTimer = Timer.periodic(interval, (_) async {
      if (_isReading) return;
      _isReading = true;

      try {
        final result = await ble.readCharacteristic(lightCharacteristic);
        print("🧾 Manuel læsning (poll): $result");
        await _handleData(result);
      } catch (e) {
        print("⚠️ BLE polling error: $e");
      } finally {
        _isReading = false;
      }
    });
  }

  Future<void> stopListening() async {
    _readTimer?.cancel();
    _readTimer = null;
    print("🔕 Stopper BLE polling-lytning");
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
      return melanopic < 250 ? "increase" : "none";
    } else if (hour >= 19 && hour < 23) {
      return melanopic > 10 ? "decrease" : "none";
    } else {
      return melanopic > 1 ? "decrease" : "none";
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

      print("📊 Decode → ${values.join(', ')}");
      print("📈 Exposure: ${exposureScore.toStringAsFixed(1)}%, action: $actionRequired, light_type: $lightType");

      // Sikring
      if (_patientId == null || _sensorId == null) {
        print("❌ patientId/sensorId mangler – afviser måling.");
        return;
      }

      print("💾 Gemmer med patient_id: $_patientId, sensor_id: $_sensorId");

      await OfflineStorageService.saveLocally(
        type: 'light',
        data: {
          "timestamp": nowString,
          "patient_id": _patientId,
          "sensor_id": _sensorId,
          "lux_level": values[0],
          "melanopic_edi": values[1],
          "der": values[2],
          "illuminance": values[3],
          "spectrum": values.sublist(4, 8),
          "light_type": values[5],
          "exposure_score": exposureScore,
          "action_required": actionRequired == "increase"
              ? 1
              : actionRequired == "decrease"
              ? 2
              : 0,
        },
      );
    } catch (e) {
      print("❌ Fejl i håndtering af BLE-data: $e");
      LocalLogService.log("⚠️ Fejl ved parsing eller upload: $e");
    }
  }
}
