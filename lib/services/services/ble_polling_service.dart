import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class BlePollingService {
  final FlutterReactiveBle ble;
  final QualifiedCharacteristic characteristic;

  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _patientId; // ✅ ændret fra int?
  String? _jwt;
  String? _sensorId;

  BlePollingService({
    required this.ble,
    required this.characteristic,
  });

  void startPolling({Duration interval = const Duration(seconds: 10)}) async {
    print("📆 Starter polling-læsning hver ${interval.inSeconds} sek. fra ${characteristic.characteristicId}");

    if (_pollingTimer?.isActive ?? false) {
      print("⛔️ Allerede aktiv polling – annullerer nyt startforsøg.");
      return;
    }

    // Hent login og sensor-oplysninger én gang
    _jwt = await AuthStorage.getToken();
    final rawId = await AuthStorage.getUserId(); // kan være int
    _patientId = rawId?.toString(); // konverteres til String?
    if (_jwt == null || _patientId == null || _patientId!.isEmpty) {
      LocalLogService.log("❌ JWT eller patient-ID mangler – kan ikke starte polling");
      return;
    }

    final serial = characteristic.characteristicId.toString();
    _sensorId = await ApiService.registerSensorUse(
      patientId: _patientId!,
      deviceSerial: serial,
      jwt: _jwt!,
    );

    if (_sensorId == null) {
      LocalLogService.log("❌ Kunne ikke registrere sensor – polling afbrudt.");
      return;
    }

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      if (_isPolling) return;
      _isPolling = true;

      try {
        final result = await ble.readCharacteristic(characteristic);
        print("🧾 Manuel læsning (poll): $result");
        await _handleData(result);
      } catch (e) {
        print("⚠️ BLE polling-fejl: $e");
        LocalLogService.log("⚠️ BLE polling-fejl: $e");
      } finally {
        _isPolling = false;
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("🛑 BLE polling stoppet");
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
      final exposureScore = _calculateExposureScore(melanopic, now);
      final actionRequired = _getActionRequired(melanopic, now);
      final lightTypeCode = values[5];
      final lightTypeName = _lightTypeFromCode(lightTypeCode);

      print("📊 Decode → ${values.join(', ')}");
      print("📈 Exposure: ${exposureScore.toStringAsFixed(1)}%, action: $actionRequired, light_type: $lightTypeName");

      if (_patientId == null || _sensorId == null) {
        print("❌ patientId/sensorId mangler – afviser måling.");
        return;
      }

      print("💾 Gemmer med patient_id: $_patientId, sensor_id: $_sensorId");

      final lightData = {
        "timestamp": nowString,
        "patient_id": _patientId,
        "sensor_id": _sensorId,
        "lux_level": values[0],
        "melanopic_edi": values[1],
        "der": values[2],
        "illuminance": values[3],
        "spectrum": values.sublist(4, 8).map((e) => e.toDouble()).toList(),
        "light_type": lightTypeCode,
        "exposure_score": exposureScore,
        "action_required": actionRequired == "increase"
            ? 1
            : actionRequired == "decrease"
            ? 2
            : 0,
      };

      await OfflineStorageService.saveLocally(
        type: 'light',
        data: lightData,
      );
    } catch (e) {
      print("❌ Fejl i håndtering af BLE-data: $e");
      LocalLogService.log("⚠️ Fejl ved parsing eller upload: $e");
    }
  }

  double _calculateExposureScore(double melanopic, DateTime now) {
    final hour = now.hour + now.minute / 60.0;
    if (hour >= 7 && hour < 19) {
      return (melanopic / 250).clamp(0.0, 1.0) * 100;
    } else if (hour >= 19 && hour < 23) {
      return (10 / (melanopic > 0 ? melanopic : 0.01)).clamp(0.0, 1.0) * 100;
    } else {
      return (1 / (melanopic > 0 ? melanopic : 0.01)).clamp(0.0, 1.0) * 100;
    }
  }

  String _getActionRequired(double melanopic, DateTime now) {
    final hour = now.hour + now.minute / 60.0;
    if (hour >= 7 && hour < 19) {
      return melanopic < 250 ? "increase" : "none";
    } else if (hour >= 19 && hour < 23) {
      return melanopic > 10 ? "decrease" : "none";
    } else {
      return melanopic > 1 ? "decrease" : "none";
    }
  }

  String _lightTypeFromCode(int code) {
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
