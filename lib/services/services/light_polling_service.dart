import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'light_classifier_service.dart';

class LightPollingService {
  final FlutterReactiveBle ble;
  final String deviceId;
  Timer? _timer;
  bool _isPolling = false;
  String? _patientId;
  String? _jwt;
  String? _sensorId;
  DateTime? _lastSavedTimestamp;

  LightClassifier? _classifier;
  List<List<double>>? _regressionMatrix;
  List<double>? _melanopicCurve;
  List<double>? _yBarCurve;

  LightPollingService({required this.ble, required this.deviceId});

  /// Starter lys-polling med default 10s interval
  Future<void> start({Duration interval = const Duration(seconds: 10)}) async {
    print("📆 Starter polling-læsning hver ${interval.inSeconds} sek.");

    if (_timer?.isActive ?? false) return;

    _jwt = await AuthStorage.getToken();
    _patientId = (await AuthStorage.getUserId())?.toString();
    if (_jwt == null || _patientId == null || _patientId!.isEmpty) {
      LocalLogService.log("❌ JWT eller patient-ID mangler – kan ikke starte polling");
      return;
    }

    _sensorId = await ApiService.registerSensorUse(
      patientId: _patientId!,
      deviceSerial: deviceId,
      jwt: _jwt!,
    );
    if (_sensorId == null) {
      LocalLogService.log("❌ Kunne ikke registrere sensor – polling stoppes.");
      return;
    }

    // Initialiser ML-model og kurver én gang
    _classifier    ??= await LightClassifier.create();
    _regressionMatrix ??= await LightClassifier.loadRegressionMatrix();
    _melanopicCurve   ??= await LightClassifier.loadCurve('assets/melanopic_curve.csv');
    _yBarCurve        ??= await LightClassifier.loadCurve('assets/ybar_curve.csv');

    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      if (_isPolling) return;
      _isPolling = true;
      try {
        final data = await ble.readCharacteristic(
          QualifiedCharacteristic(
            deviceId: deviceId,
            serviceId: Uuid.parse('0000181b-0000-1000-8000-00805f9b34fb'),
            characteristicId: Uuid.parse('834419a6-b6a4-4fed-9afb-acbb63465bf7'),
          ),
        );
        await _handleData(data);
      } catch (e) {
        LocalLogService.log("⚠️ BLE-fejl: $e");
      } finally {
        _isPolling = false;
      }
    });
  }

  /// Stop lys-polling
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleData(List<int> data) async {
    if (data.length < 48 || data.length % 4 != 0) return;

    try {
      final now = DateTime.now();
      if (_lastSavedTimestamp != null &&
          now.difference(_lastSavedTimestamp!).inSeconds < 5) {
        return;
      }
      _lastSavedTimestamp = now;

      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      final values = List.generate(12, (i) => byteData.getInt32(i * 4, Endian.little));
      final rawInput = values.sublist(0, 8).map((e) => e.toDouble()).toList();
      final classId = _classifier!.classify(rawInput);
      final lightTypeName = _lightTypeFromCode(classId);

      // Debug-print
      print("🐞 rawInput=$rawInput");
      print("🐞 classId=$classId, lightTypeName=$lightTypeName");

      // Beregninger
      final weights     = _regressionMatrix![classId];
      final spectrum    = LightClassifier.reconstructSpectrum(rawInput, weights, normalizationFactor: 1 / 1000.0);
      final melanopic   = LightClassifier.calculateMelanopicEDI(spectrum, _melanopicCurve!);
      final spectrumLux = LightClassifier.reconstructSpectrum(rawInput, weights, normalizationFactor: 1 / 1000000.0);
      final illuminance= LightClassifier.calculateIlluminance(spectrumLux, _yBarCurve!);
      final der         = melanopic / (illuminance > 0 ? illuminance : 1.0);
      final exposureScore  = _calculateExposureScore(melanopic, now);
      final actionRequired = _getActionRequired(exposureScore, now);
      int actionCode = (actionRequired == "increase") ? 1 : (actionRequired == "decrease") ? 2 : 0;

      final lightData = {
        "timestamp": now.toIso8601String(),
        "patient_id": _patientId,
        "sensor_id": _sensorId,
        "light_type": classId,
        "light_type_name": lightTypeName,
        "lux_level": illuminance.round(),
        "melanopic_edi": melanopic,
        "der": der,
        "illuminance": illuminance,
        "spectrum": spectrum,
        "exposure_score": exposureScore,
        "action_required": actionCode,
      };

      print("💾 Gemmer lysdata med lystype=$lightTypeName og payload: $lightData");
      await OfflineStorageService.saveLocally(type: 'light', data: lightData);
      print("▶️ Data gemt kl. ${DateTime.now().toIso8601String()}");
    } catch (e) {
      LocalLogService.log("❌ BLE-datafejl: $e");
    }
  }

  double _calculateExposureScore(double melanopic, DateTime now) {
    final h = now.hour;
    if (h >= 7 && h <= 19) return (melanopic / 150).clamp(0.0, 1.0) * 100;
    if (h <= 23) return (melanopic / 50).clamp(0.0, 1.0) * 100;
    return (melanopic / 30).clamp(0.0, 1.0) * 100;
  }

  String _getActionRequired(double exposureScore, DateTime now) {
    final hourFraction = now.hour + now.minute / 60.0;
    if (hourFraction >= 7 && hourFraction < 19) {
      final result = exposureScore < 80 ? "increase" : "none";
      print("🕒 Time: $hourFraction → Action: $result (DAY)");
      return result;
    } else {
      final result = exposureScore > 20 ? "decrease" : "none";
      print("🌙 Time: $hourFraction → Action: $result (NIGHT)");
      return result;
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
