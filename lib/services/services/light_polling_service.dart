// lib/services/services/light_polling_service.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/local_log_service.dart';

import 'light_classifier_service.dart';

class LightPollingService {
  final FlutterReactiveBle _ble;
  final QualifiedCharacteristic _char;
  final String _patientId;
  final String _sensorId;

  Timer? _timer;
  bool _isPolling = false;
  DateTime? _lastSavedTimestamp;

  LightClassifier?   _classifier;
  List<List<double>>? _regressionMatrix;
  List<double>?       _melanopicCurve;
  List<double>?       _yBarCurve;

  LightPollingService({
    required FlutterReactiveBle ble,
    required QualifiedCharacteristic characteristic,
    required String patientId,
    required String sensorId,
  })  : _ble       = ble,
        _char      = characteristic,
        _patientId = patientId,
        _sensorId  = sensorId;

  /// Start polling. Kør én gang efter du har konnectet.
  Future<void> start({Duration interval = const Duration(seconds: 10)}) async {
    if (_timer?.isActive ?? false) return;

    // Load ML-model og kurver én gang
    _classifier       ??= await LightClassifier.create();
    _regressionMatrix ??= await LightClassifier.loadRegressionMatrix();
    _melanopicCurve   ??= await LightClassifier.loadCurve('assets/melanopic_curve.csv');
    _yBarCurve        ??= await LightClassifier.loadCurve('assets/ybar_curve.csv');

    _timer = Timer.periodic(interval, (_) => _poll());
  }

  /// Stop polling
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final data = await _ble.readCharacteristic(_char);
      await _handleData(data);
    } catch (e) {
      LocalLogService.log("⚠️ Lys-polling-BLE-fejl: $e");
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _handleData(List<int> data) async {
    // Vi forventer præcis 12 × 4 bytes
    if (data.length < 48 || data.length % 4 != 0) return;

    final now = DateTime.now();
    // Undgå dubletter
    if (_lastSavedTimestamp != null &&
        now.difference(_lastSavedTimestamp!).inSeconds < 5) {
      return;
    }
    _lastSavedTimestamp = now;

    try {
      // 1) Decode rå ADC-værdier
      final bytes  = ByteData.sublistView(Uint8List.fromList(data));
      final values = List.generate(
        12,
            (i) => bytes.getInt32(i * 4, Endian.little),
      );
      final rawInput = values.sublist(0, 8).map((e) => e.toDouble()).toList();

      // 2) Klassificér lys-type og hent de regressions-vægte
      final classId = _classifier!.classify(rawInput);
      final weights = _regressionMatrix![classId];

      // 3) 🔹 Brug 1/1000.0 til melanopic-beregning
      final spectrum = LightClassifier.reconstructSpectrum(
        rawInput,
        weights,
        normalizationFactor: 1 / 1000.0,
      );
      final melanopic = LightClassifier.calculateMelanopicEDI(
        spectrum,
        _melanopicCurve!,
      );

      // 4) 🔹 Brug 1/1_000_000.0 til illuminance-beregning
      final spectrumLux = LightClassifier.reconstructSpectrum(
        rawInput,
        weights,
        normalizationFactor: 1 / 1000000.0,
      );
      final illuminance = LightClassifier.calculateIlluminance(
        spectrumLux,
        _yBarCurve!,
      );

      // 5) Beregn DER, score og action
      final der    = melanopic / (illuminance > 0 ? illuminance : 1.0);
      final score  = _calcScore(melanopic, now);
      final action = _calcAction(score, now);

      // 6) Sammensæt payload
      final payload = {
        "timestamp":       now.toIso8601String(),
        "patient_id":      _patientId,
        "sensor_id":       _sensorId,
        "light_type":      classId,
        "light_type_name": _typeName(classId),
        "lux_level":       illuminance.round(),
        "melanopic_edi":   melanopic,
        "der":             der,
        "illuminance":     illuminance,
        "spectrum":        spectrum,     // det 400-punkt spektrum for EDI
        "exposure_score":  score,
        "action_required": action,
      };

      await OfflineStorageService.saveLocally(type: 'light', data: payload);
      print("▶️ Lysdata gemt kl. ${now.toIso8601String()}");
    } catch (e) {
      LocalLogService.log("❌ Fejl i lys-datahåndtering: $e");
    }
  }

  double _calcScore(double melanopic, DateTime now) {
    final h = now.hour;
    if (h >= 7 && h < 19) return (melanopic / 150).clamp(0.0, 1.0) * 100;
    if (h < 24)             return (melanopic /  50).clamp(0.0, 1.0) * 100;
    return                   (melanopic /  30).clamp(0.0, 1.0) * 100;
  }

  int _calcAction(double score, DateTime now) {
    final frac = now.hour + now.minute / 60.0;
    if (frac >= 7 && frac < 19) return score < 80 ? 1 : 0;
    return score > 20 ? 2 : 0;
  }

  String _typeName(int code) {
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
