import 'package:flutter/foundation.dart';

import '../../models/patient_model.dart';
import '../../models/diagnose_model.dart';
import '../../models/light_data_model.dart';
import '../../models/patient_event_model.dart';
import '../../services/services/api_services.dart';
import '../../services/processing/data_processing_manager.dart';

class PatientDetailViewModel extends ChangeNotifier {
  final String patientId;
  final DataProcessingManager _dataProcessingManager;

  PatientDetailViewModel(this.patientId)
      : _dataProcessingManager = DataProcessingManager() {
    lightDataFuture = _fetchRawLightData();
  }

  bool _isFetchingRaw = false;
  bool get isFetchingRaw => _isFetchingRaw;

  String? _rawFetchError;
  String? get rawFetchError => _rawFetchError;

  List<LightData> _rawLightData = [];
  List<LightData> get rawLightData => _rawLightData;

  late final Future<void> lightDataFuture;
  Future<void> _fetchRawLightData() async {
    _isFetchingRaw = true;
    _rawFetchError = null;
    notifyListeners();

    try {
      final String patientIdForLightData = kDebugMode ? 'P3' : patientId;

      if (kDebugMode) {
        debugPrint('[DEBUG MODE] Henter lysdata for P3 i stedet for $patientId');
      }

      final list = await ApiService.getPatientLightData(patientIdForLightData);
      final rawList = list.map((e) => LightData.fromJson(e)).toList();
      _rawLightData = rawList;
      _isFetchingRaw = false;
      notifyListeners();

      await _triggerProcessYesterday();
    } catch (e) {
      _rawFetchError = e.toString();
      _rawLightData = [];
      _isFetchingRaw = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dataProcessingManager.disposeModel();
    super.dispose();
  }

  ProcessedLightData? _processedLightData;
  ProcessedLightData? get processedLightData => _processedLightData;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  Future<void> _triggerProcessYesterday() async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final todayMid = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayMid.subtract(const Duration(days: 1));
      final yesterdayEnd =
      todayMid.subtract(const Duration(seconds: 1));

      final yesterdayData = _rawLightData.where((e) {
        final dt = e.capturedAt.toLocal();
        return dt.isAfter(yesterdayStart) &&
            dt.isBefore(yesterdayEnd);
      }).toList();

      if (yesterdayData.isEmpty) {
        _error = 'Ingen lysdata fra i går';
        _processedLightData = null;
      } else {
        final input = yesterdayData.map((e) => e.ediLux).toList();
        final res =
        await _dataProcessingManager.runProcessData(input);
        if (res != null) {
          _processedLightData = ProcessedLightData(
            timestamp: DateTime.now(),
            medi: res.medi,
            fThreshold: res.fThreshold,
            mediDuration: res.mediDuration,
          );
        }
      }
    } catch (e) {
      _error = 'Fejl ved ML‐bearbejdning: $e';
      _processedLightData = null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> refreshProcessedData() => _triggerProcessYesterday();

  Patient? _patient;
  Future<Patient>? _patientFuture;
  Future<Patient> fetchPatientDetails() {
    return _patientFuture ??= ApiService.getPatientDetails(patientId)
        .then((p) {
      _patient = p;
      notifyListeners();
      return p;
    });
  }

  Future<List<Diagnosis>>? _diagFuture;
  Future<List<Diagnosis>> fetchDiagnoses() {
    return _diagFuture ??= ApiService.getPatientDiagnoses(patientId)
        .then((list) => list.map((e) => Diagnosis.fromJson(e)).toList());
  }

  Future<List<PatientEvent>>? _evtFuture;
  Future<List<PatientEvent>> fetchPatientEvents() {
    return _evtFuture ??= ApiService.fetchActivities(patientId)
        .then((list) => list.map((e) => PatientEvent.fromJson(e)).toList());
  }

  double get rmeqScore => (_patient?.rmeqScore ?? 0).toDouble();
  int? get storedMeqScore => _patient?.meqScore;
}
