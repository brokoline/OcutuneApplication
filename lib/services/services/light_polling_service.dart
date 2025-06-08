// lib/services/services/light_polling_service.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/light_classifier_service.dart';

// Service for polling the light sensor med faste intervaller.
class LightPollingService {
  final FlutterReactiveBle _ble;
  final QualifiedCharacteristic _char;
  final String _patientId;
  final String _sensorId;

  Timer? _timer;
  bool _isPolling = false;
  DateTime? _lastSavedTimestamp; // For duplicate protection

  late final LightClassifier _classifier;
  late final List<List<double>> _regressionMatrix;
  late final List<double> _melanopicCurve;
  late final List<double> _yBarCurve;

  LightPollingService({
    required FlutterReactiveBle ble,
    required QualifiedCharacteristic characteristic,
    required String patientId,
    required String sensorId,
  })
      : _ble = ble,
        _char = characteristic,
        _patientId = patientId,
        _sensorId = sensorId;

  /// Starter classifier/data og sætter et periodic‐timer op.
  ///
  /// Første poll sker _med det samme_, herefter præcis hvert [interval].
  Future<void> start({Duration interval = const Duration(seconds: 10)}) async {
    if (_timer?.isActive ?? false) return;

    // 1) Indlæs ML-model og curves
    _classifier = await LightClassifier.create();
    _regressionMatrix = await LightClassifier.loadRegressionMatrix();
    _melanopicCurve =
    await LightClassifier.loadCurve('assets/melanopic_curve.csv');
    _yBarCurve = await LightClassifier.loadCurve('assets/ybar_curve.csv');

    // 2) Første poll _med det samme_
    _poll();

    // 3) Derefter hvert [interval]
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  /// Stopper periodic polling.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final data = await _ble.readCharacteristic(_char);
      await _handleData(data);
    } catch (e) {
      print('⚠️ BLE polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _handleData(List<int> data) async {
    // Expect 12 × 4 bytes of raw ADC data
    if (data.length < 48 || data.length % 4 != 0) {
      print(
          '❌ Invalid BLE data length: ${data.length} bytes - ignoring packet');
      return;
    }

    final now = DateTime.now();

    // Duplicate protection: ignore if measurement is too close to last one
    if (_lastSavedTimestamp != null &&
        now
            .difference(_lastSavedTimestamp!)
            .inSeconds < 5) {
      print('🛑 Ignoring duplicate measurement: ${now.toIso8601String()}');
      return;
    }

    _lastSavedTimestamp = now;

    try {
      final bytes = ByteData.sublistView(Uint8List.fromList(data));
      final values = List<double>.generate(
        data.length ~/ 4,
            (i) => bytes.getInt32(i * 4, Endian.little).toDouble(),
      );
      final rawInput = values.sublist(0, 8);

      final classId = _classifier.classify(rawInput);
      final typeName = _typeName(classId);

      if (classId < 0 || classId >= _regressionMatrix.length) {
        throw Exception(
            '❌ Invalid classId: $classId - out of bounds for regressionMatrix');
      }

      final weights = _regressionMatrix[classId];

      // Melanopic EDI
      final spectrumMel = LightClassifier.reconstructSpectrum(
        rawInput,
        weights,
        normalizationFactor: 1 / 1000.0,
      );
      final melanopicEdi = LightClassifier.calculateMelanopicEDI(
        spectrumMel,
        _melanopicCurve,
      );

      // Photopic illuminance
      final spectrumLux = LightClassifier.reconstructSpectrum(
        rawInput,
        weights,
        normalizationFactor: 1 / 1000000.0,
      );
      final illuminance = LightClassifier.calculateIlluminance(
        spectrumLux,
        _yBarCurve,
      );

      // Calculate DER (melanopic to illuminance ratio)
      final der = melanopicEdi / (illuminance > 0 ? illuminance : 1.0);

      // Calculate exposure score and required action
      final exposureScore = _calculateExposureScore(melanopicEdi, now);
      final actionRequired = _getActionRequired(exposureScore, now);
      final actionCode = (actionRequired == "increase") ? 1 : (actionRequired ==
          "decrease") ? 2 : 0;

      final payload = {
        'timestamp': now.toIso8601String(),
        'patient_id': _patientId,
        'sensor_id': _sensorId,
        'light_type': classId,
        'light_type_name': typeName,
        'lux_level': illuminance.round(),
        'melanopic_edi': melanopicEdi,
        'der': der,
        'illuminance': illuminance,
        'exposure_score': exposureScore,
        'action_required': actionCode,
        'spectrum': spectrumMel,
      };

      print('📊 Light data:');
      print('🧠 ClassId: $classId ($typeName)');
      print('📈 EDI: ${melanopicEdi.toStringAsFixed(1)}, Lux: ${illuminance
          .toStringAsFixed(1)}, DER: ${der.toStringAsFixed(4)}');
      print('📈 Exposure: ${exposureScore.toStringAsFixed(
          1)}%, action: $actionRequired');

      await OfflineStorageService.saveLocally(type: 'light', data: payload);
      print('▶️ Light data saved at ${now.toIso8601String()}');
    } catch (e) {
      print('❌ Error handling light data: $e');
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
      print(
          "🌙 Time: $hour, Exposure: $exposureScore% → Action: $result (NIGHT)");
      return result;
    }
  }

  String _typeName(int code) {
    switch (code) {
      case 0:
        return 'Daylight';
      case 1:
        return 'LED';
      case 2:
        return 'Mixed';
      case 3:
        return 'Halogen';
      case 4:
        return 'Fluorescent';
      case 5:
        return 'Fluorescent daylight';
      case 6:
        return 'Screen';
      default:
        return 'Unknown';
    }
  }

  Future<void> handleData(List<int> data) async {
    await _handleData(data);
  }
}