// lib/services/services/light_polling_service.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/light_classifier_service.dart';

/// Service for polling the light sensor at fixed intervals and processing measurements.
class LightPollingService {
  final FlutterReactiveBle _ble;
  final QualifiedCharacteristic _char;
  final String _patientId;
  final String _sensorId;

  Timer? _timer;
  bool _isPolling = false;
  DateTime? _lastSavedTimestamp;

  late final LightClassifier _classifier;
  late final List<List<double>> _regressionMatrix;
  late final List<double> _melanopicCurve;
  late final List<double> _yBarCurve;

  LightPollingService({
    required FlutterReactiveBle ble,
    required QualifiedCharacteristic characteristic,
    required String patientId,
    required String sensorId,
  })  : _ble = ble,
        _char = characteristic,
        _patientId = patientId,
        _sensorId = sensorId;

  /// Initializes classifier and data, then starts periodic polling every [interval].
  Future<void> start({Duration interval = const Duration(seconds: 10)}) async {
    if (_timer?.isActive ?? false) return;

    _classifier = await LightClassifier.create();
    _regressionMatrix = await LightClassifier.loadRegressionMatrix();
    _melanopicCurve = await LightClassifier.loadCurve('assets/melanopic_curve.csv');
    _yBarCurve = await LightClassifier.loadCurve('assets/ybar_curve.csv');

    _timer = Timer.periodic(interval, (_) => _poll());
  }

  /// Stops periodic polling.
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
    if (data.length < 48 || data.length % 4 != 0) return;

    final now = DateTime.now();
    if (_lastSavedTimestamp != null &&
        now.difference(_lastSavedTimestamp!).inSeconds < 10) {
      return; // debounce duplicates within one interval
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
      print('💡 Light type: $typeName (code $classId)');

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

      final der = melanopicEdi / (illuminance > 0 ? illuminance : 1.0);
      final score = _calcScore(melanopicEdi, now);
      final action = _calcAction(score, now);

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
        'spectrum': spectrumMel,
        'exposure_score': score,
        'action_required': action,
      };

      await OfflineStorageService.saveLocally(type: 'light', data: payload);
      print('▶️ Light data saved at ${now.toIso8601String()}');
    } catch (e) {
      print('❌ Error handling light data: $e');
    }
  }

  double _calcScore(double melanopic, DateTime now) {
    final h = now.hour;
    if (h >= 7 && h < 19) {
      return (melanopic / 150).clamp(0.0, 1.0) * 100;
    } else if (h >= 19 || h < 7) {
      return (melanopic / 50).clamp(0.0, 1.0) * 100;
    }
    return (melanopic / 30).clamp(0.0, 1.0) * 100;
  }

  int _calcAction(double score, DateTime now) {
    final frac = now.hour + now.minute / 60.0;
    if (frac >= 7 && frac < 19) {
      return score < 80 ? 1 : 0;
    }
    return score > 20 ? 2 : 0;
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
}