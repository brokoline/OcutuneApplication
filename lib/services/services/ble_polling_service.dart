import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import '../../widgets/clinician_widgets/clinician_search_widgets/patient_data_widgets/light_classifier.dart';

class BlePollingService {
  final FlutterReactiveBle ble;
  final QualifiedCharacteristic characteristic;

  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _patientId;
  String? _jwt;
  String? _sensorId;

  LightClassifier? _classifier;
  List<List<double>>? _regressionMatrix;
  List<double>? _melanopicCurve;
  List<double>? _yBarCurve;

  BlePollingService({required this.ble, required this.characteristic});

  void startPolling({Duration interval = const Duration(seconds: 10)}) async {
    print("📆 Starter polling-læsning hver ${interval.inSeconds} sek.");

    if (_pollingTimer?.isActive ?? false) {
      print("⛔️ Allerede aktiv polling – afbryder.");
      return;
    }

    _jwt = await AuthStorage.getToken();
    final rawId = await AuthStorage.getUserId();
    _patientId = rawId?.toString();

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
      LocalLogService.log("❌ Kunne ikke registrere sensor – polling stoppes.");
      return;
    }

    try {
      _classifier ??= await LightClassifier.create();
      _regressionMatrix ??= await LightClassifier.loadRegressionMatrix();
      _melanopicCurve ??= await LightClassifier.loadCurve("assets/melanopic_curve.csv");
      _yBarCurve ??= await LightClassifier.loadCurve("assets/ybar_curve.csv");
    } catch (e) {
      LocalLogService.log("❌ Fejl ved initialisering: $e");
      return;
    }

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      if (_isPolling) return;
      _isPolling = true;

      try {
        final result = await ble.readCharacteristic(characteristic);
        print("📦 Rå BLE-data: $result");
        await _handleData(result);
      } catch (e) {
        print("⚠️ BLE-fejl: $e");
        LocalLogService.log("⚠️ BLE-fejl: $e");
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
    if (data.length < 48 || data.length % 4 != 0) {
      print("❌ Ugyldig BLE-data længde: ${data.length} bytes – ignorerer pakken.");
      return;
    }

    try {
      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      final values = List.generate(12, (i) => byteData.getInt32(i * 4, Endian.little));

      if (_classifier == null || _regressionMatrix == null || _melanopicCurve == null || _yBarCurve == null) {
        throw Exception("🔧 ML-model, regression eller kurver ikke initialiseret.");
      }

      final now = DateTime.now();
      final nowString = now.toIso8601String();
      final rawInput = values.sublist(0, 8).map((e) => e.toDouble()).toList();

      final classId = _classifier!.classify(rawInput);
      if (classId < 0 || classId >= _regressionMatrix!.length) {
        throw Exception("❌ Ugyldigt classId: $classId – udenfor bounds for regressionMatrix");
      }

      final weights = _regressionMatrix![classId];
      final spectrum = LightClassifier.reconstructSpectrum(rawInput, weights);

      final melanopic = LightClassifier.calculateMelanopicEDI(spectrum, _melanopicCurve!);
      final illuminance = LightClassifier.calculateIlluminance(spectrum, _yBarCurve!);
      final der = melanopic / (illuminance > 0 ? illuminance : 1);

      final exposureScore = _calculateExposureScore(melanopic, now);
      final actionRequired = _getActionRequired(melanopic, now);
      final lightTypeName = _lightTypeFromCode(classId);

      print("📊 Decode → ${values.join(', ')}");
      print("🧠 ClassId: $classId ($lightTypeName)");
      print("📈 EDI: ${melanopic.toStringAsFixed(1)}, Lux: ${illuminance.toStringAsFixed(1)}, DER: ${der.toStringAsFixed(4)}");
      print("📈 Exposure: ${exposureScore.toStringAsFixed(1)}%, action: $actionRequired");

      if (_patientId == null || _sensorId == null) return;

      final lightData = {
        "timestamp": nowString,
        "patient_id": _patientId,
        "sensor_id": _sensorId,
        "lux_level": illuminance.round(),
        "melanopic_edi": melanopic,
        "der": der,
        "illuminance": illuminance,
        "spectrum": spectrum,
        "light_type": classId,
        "exposure_score": exposureScore,
        "action_required": actionRequired == "increase"
            ? 1
            : actionRequired == "decrease"
            ? 2
            : 0,
      };

      print("📬 saveLocally kaldes med type: light, data: $lightData");

      await OfflineStorageService.saveLocally(type: 'light', data: lightData);
    } catch (e) {
      print("❌ Fejl i håndtering af BLE-data: $e");
      LocalLogService.log("❌ BLE-datafejl: $e");
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
}
