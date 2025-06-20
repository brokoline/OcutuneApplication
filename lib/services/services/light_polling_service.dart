// lib/services/services/light_polling_service.dart

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/services/light_classifier_service.dart';

import '../../controller/ble_controller.dart';

// Service der periodisk læser lys-data fra sensoren.
class LightPollingService {
  final QualifiedCharacteristic _char;
  final String _patientId;
  final String _sensorId;

  Timer? _timer;
  bool _isPolling = false;
  DateTime? _lastSavedTimestamp;

  late final LightClassifier       _classifier;
  late final List<List<double>>    _regressionMatrix;
  late final List<double>          _melanopicCurve;
  late final List<double>          _yBarCurve;

  LightPollingService({
    required FlutterReactiveBle ble,
    required QualifiedCharacteristic characteristic,
    required String patientId,
    required String sensorId,
  })  : _char      = characteristic,
        _patientId = patientId,
        _sensorId  = sensorId;

  // Starter et første _poll()_ med lidt jitter, og herefter præcist hvert [interval].
  Future<void> start({ Duration interval = const Duration(seconds: 10) }) async {
    if (_timer?.isActive ?? false) return;


    // 1) Indlæs ML-model og kurver
    _classifier       = await LightClassifier.create();
    _regressionMatrix = await LightClassifier.loadRegressionMatrix();
    _melanopicCurve   = await LightClassifier.loadCurve('assets/melanopic_curve.csv');
    _yBarCurve        = await LightClassifier.loadCurve('assets/ybar_curve.csv');

    // 2) Første poll med lille jitter (0–500 ms)
    final firstJitter = Duration(milliseconds: Random().nextInt(500));
    await Future.delayed(firstJitter);
    await _poll();

    // 3) Planlæg herefter præcis hvert [interval]
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  // Stopper den periodiske polling.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  // Ét enkelt poll-kald, som kun kører hvis vi ikke allerede er i gang.
  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final data = await BleController().safeReadCharacteristic(_char);
      await _handleData(data);
    } catch (e) {
      print('⚠️ BLE polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _handleData(List<int> data) async {
    // Tjek længde
    if (data.length < 48 || data.length % 4 != 0) {
      print('❌ Invalid BLE data length: ${data.length} bytes - ignoring packet');
      return;
    }

    final now = DateTime.now();
    // Undgå duplikater inden for 5 sek.
    if (_lastSavedTimestamp != null &&
        now.difference(_lastSavedTimestamp!).inSeconds < 1.5) {
      print('🛑 Ignoring duplicate measurement: ${now.toIso8601String()}');
      return;
    }
    _lastSavedTimestamp = now;

    try {
      // Parse rå bytes
      final bytes = ByteData.sublistView(Uint8List.fromList(data));
      final values = List<double>.generate(
        data.length ~/ 4,
            (i) => bytes.getInt32(i * 4, Endian.little).toDouble(),
      );
      final rawInput = values.sublist(0, 8);

      // Klassificér og rekonstruér spektrer
      final classId  = _classifier.classify(rawInput);
      final typeName = _typeName(classId);
      if (classId < 0 || classId >= _regressionMatrix.length) {
        throw Exception('❌ Invalid classId: $classId');
      }
      final weights = _regressionMatrix[classId];

      final spectrumMel = LightClassifier.reconstructSpectrum(
        rawInput, weights, normalizationFactor: 1 / 1000.0,
      );
      final melanopicEdi = LightClassifier.calculateMelanopicEDI(
        spectrumMel, _melanopicCurve,
      );
      final spectrumLux = LightClassifier.reconstructSpectrum(
        rawInput, weights, normalizationFactor: 1 / 1000000.0,
      );
      final illuminance = LightClassifier.calculateIlluminance(
        spectrumLux, _yBarCurve,
      );

      final der = melanopicEdi / (illuminance > 0 ? illuminance : 1.0);

      final exposureScore = _calculateExposureScore(melanopicEdi, now);
      final actionRequired = _getActionRequired(exposureScore, now);
      final actionCode = actionRequired == 'increase'
          ? 1 : actionRequired == 'decrease' ? 2 : 0;

      // gemmer payload lokalt
      final payload = {
        'timestamp'      : now.toIso8601String(),
        'patient_id'     : _patientId,
        'sensor_id'      : _sensorId,
        'light_type'     : classId,
        'light_type_name': typeName,
        'lux_level'      : illuminance.round(),
        'melanopic_edi'  : melanopicEdi,
        'der'            : der,
        'illuminance'    : illuminance,
        'exposure_score' : exposureScore,
        'action_required': actionCode,
      };

      print('📊 Light data:');
      print('🧠 ClassId: $classId ($typeName)');
      print('📈 EDI: ${melanopicEdi.toStringAsFixed(1)}, '
          'Lux: ${illuminance.toStringAsFixed(1)}, '
          'DER: ${der.toStringAsFixed(4)}');
      print('📈 Exposure: ${exposureScore.toStringAsFixed(1)}%, '
          'action: $actionRequired');


      // Gem til senere upload
      await OfflineStorageService.saveLocally(type: 'light', data: payload);
      print('▶️ Light data saved at ${now.toIso8601String()}');
    } catch (e) {
      print('❌ Error handling light data: $e');
    }
  }

  double _calculateExposureScore(double melanopic, DateTime now) {
    final h = now.hour;
    if (h >= 7 && h <= 19) return (melanopic / 150).clamp(0.0, 1.0) * 100;
    if (h > 19 && h <= 23) return (melanopic / 50).clamp(0.0, 1.0) * 100;
    return (melanopic / 30).clamp(0.0, 1.0) * 100;
  }

  String _getActionRequired(double score, DateTime now) {
    final hour = now.hour + now.minute / 60.0;
    if (hour >= 7 && hour < 19) {
      final res = score < 80 ? 'increase' : 'none';
      print('🕒 Time: $hour, Exposure: $score% → Action: $res (DAY)');
      return res;
    } else {
      final res = score > 20 ? 'decrease' : 'none';
      print('🌙 Time: $hour, Exposure: $score% → Action: $res (NIGHT)');
      return res;
    }
  }

  String _typeName(int code) {
    switch (code) {
      case 0: return 'Daylight';
      case 1: return 'LED';
      case 2: return 'Mixed';
      case 3: return 'Halogen';
      case 4: return 'Fluorescent';
      case 5: return 'Fluorescent daylight';
      case 6: return 'Screen';
      default: return 'Unknown';
    }
  }

  Future<void> handleData(List<int> data) async {
    await _handleData(data);
  }
}
