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

  BlePollingService({
    required this.ble,
    required this.characteristic,
  });

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    print("📆 Starter BLE polling hver ${interval.inSeconds} sek.");

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      if (_isPolling) return;
      _isPolling = true;

      try {
        final rawData = await ble.readCharacteristic(characteristic);
        await _handleData(rawData);
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
    if (data.length < 48) {
      print("⚠️ Data for kort – ignorerer.");
      return;
    }

    final jwt = await AuthStorage.getToken();
    final patientId = await AuthStorage.getUserId();

    if (jwt == null || patientId == null) {
      print("❌ JWT eller patient-ID mangler");
      return;
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(data));
    final values = List.generate(12, (i) => byteData.getInt32(i * 4, Endian.little));
    final timestamp = DateTime.now().toIso8601String();

    final spectrum = values.sublist(4, 8).map((e) => e.toDouble()).toList();
    final lightTypeCode = values[5];
    final exposureScore = _calculateExposureScore(values[1].toDouble());
    final actionRequired = _getActionRequired(values[1].toDouble());

    final serial = characteristic.characteristicId.toString();
    final sensorId = await ApiService.registerSensorUse(
      patientId: patientId,
      deviceSerial: serial,
      jwt: jwt,
    );

    if (sensorId == null) {
      print("❌ Sensor ID ikke registreret");
      return;
    }

    final lightData = {
      "timestamp": timestamp,
      "patient_id": patientId,
      "sensor_id": sensorId,
      "lux_level": values[0],
      "melanopic_edi": values[1],
      "der": values[2],
      "illuminance": values[3],
      "spectrum": spectrum,
      "light_type": lightTypeCode,
      "exposure_score": exposureScore,
      "action_required": actionRequired ? 1 : 0,
    };

    print("📥 Modtaget lysdata: $lightData");
    await OfflineStorageService.saveLocally(
      type: 'light',
      data: lightData,
    );
  }

  double _calculateExposureScore(double melanopic) {
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;
    if (hour >= 7 && hour < 19) {
      return (melanopic / 250).clamp(0.0, 1.0) * 100;
    } else if (hour >= 19 && hour < 23) {
      return (10 / (melanopic > 0 ? melanopic : 0.01)).clamp(0.0, 1.0) * 100;
    } else {
      return (1 / (melanopic > 0 ? melanopic : 0.01)).clamp(0.0, 1.0) * 100;
    }
  }

  bool _getActionRequired(double melanopic) {
    final hour = DateTime.now().hour + DateTime.now().minute / 60.0;
    if (hour >= 7 && hour < 19) {
      return melanopic < 250;
    } else if (hour >= 19 && hour < 23) {
      return melanopic > 10;
    } else {
      return melanopic > 1;
    }
  }
}
