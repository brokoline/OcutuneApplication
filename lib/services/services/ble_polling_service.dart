import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'light_classifier_service.dart';

class BlePollingService {
  final FlutterReactiveBle ble;
  final QualifiedCharacteristic characteristic;

  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _patientId;
  String? _jwt;
  String? _sensorId;

  DateTime? _lastSavedTimestamp;

  LightClassifier? _classifier;
  List<List<double>>? _regressionMatrix;
  List<double>? _melanopicCurve;
  List<double>? _yBarCurve;

  BlePollingService({required this.ble, required this.characteristic});

  void startPolling({Duration interval = const Duration(seconds: 10)}) async {
    print("📆 Starter polling-læsning hver ${interval.inSeconds} sek.");

    if (_pollingTimer?.isActive ?? false) {
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
        await _handleData(result);
      } catch (e) {
        LocalLogService.log("⚠️ BLE-fejl: $e");
      } finally {
        _isPolling = false;
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _handleData(List<int> data) async {
    if (data.length < 48 || data.length % 4 != 0) {
      return;
    }

    try {
      final now = DateTime.now();

      // 🔹 Dubletbeskyttelse: ignorér hvis måling kom for tæt på sidste
      if (_lastSavedTimestamp != null &&
          now.difference(_lastSavedTimestamp!).inSeconds < 5) {
        return;
      }

      _lastSavedTimestamp = now;

      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      final values = List.generate(12, (i) => byteData.getInt32(i * 4, Endian.little));

      if (_classifier == null || _regressionMatrix == null || _melanopicCurve == null || _yBarCurve == null) {
        throw Exception("ML-model, regression eller kurver ikke initialiseret.");
      }

      final nowString = now.toIso8601String();
      final rawInput = values.sublist(0, 8).map((e) => e.toDouble()).toList();

      final classId = _classifier!.classify(rawInput);
      if (classId < 0 || classId >= _regressionMatrix!.length) {
        throw Exception("Ugyldigt classId: $classId – udenfor bounds for regressionMatrix");
      }

      // 🔹 Bestem lystypens navn
      final lightTypeName = _lightTypeFromCode(classId);
      print("💡 Lystype: $lightTypeName (kode $classId)");

      final weights = _regressionMatrix![classId];

      // 🔹 Bruger 1/1000.0 til melanopic-beregning
      final spectrum = LightClassifier.reconstructSpectrum(rawInput, weights, normalizationFactor: 1 / 1000.0);
      final melanopic = LightClassifier.calculateMelanopicEDI(spectrum, _melanopicCurve!);

      // 🔹 Bruger 1/1_000_000.0 til illuminance-beregning
      final spectrumLux = LightClassifier.reconstructSpectrum(rawInput, weights, normalizationFactor: 1 / 1000000.0);
      final illuminance = LightClassifier.calculateIlluminance(spectrumLux, _yBarCurve!);

      final der = melanopic / (illuminance > 0 ? illuminance : 1.0);

      final exposureScore = _calculateExposureScore(melanopic, now);
      final actionRequired = _getActionRequired(exposureScore, now);
      int actionCode = (actionRequired == "increase") ? 1 : (actionRequired == "decrease") ? 2 : 0;

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
        "light_type_name": lightTypeName,  // 🔹 Tilføjet navn
        "exposure_score": exposureScore,
        "action_required": actionCode,
      };

      print("▶️ Nyt BLE‐aflæsningstag kl. ${DateTime.now().toIso8601String()}");
      await OfflineStorageService.saveLocally(type: 'light', data: lightData);
    } catch (e) {
      print("❌ Fejl i håndtering af BLE-data: $e");
      LocalLogService.log("❌ BLE-datafejl: $e");
    }
  }

  double _calculateExposureScore(double melanopic, DateTime now) {
    final hour = now.hour;
    if (hour >= 7 && hour <= 19) {
      return (melanopic / 150).clamp(0.0, 1.0) * 100;
    } else if (hour > 19 && hour <= 23) {
      return (melanopic / 50).clamp(0.0, 1.0) * 100;
    } else {
      return (melanopic / 30).clamp(0.0, 1.0) * 100;
    }
  }

  String _getActionRequired(double exposureScore, DateTime now) {
    final hour = now.hour + now.minute / 60.0;
    if (hour >= 7 && hour < 19) {
      final result = exposureScore < 80 ? "increase" : "none";
      print("🕒 Time: $hour, Exposure: $exposureScore% → Action: $result (DAY)");
      return result;
    } else {
      final result = exposureScore > 20 ? "decrease" : "none";
      print("🌙 Time: $hour, Exposure: $exposureScore% → Action: $result (NIGHT)");
      return result;
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
