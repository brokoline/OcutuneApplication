// lib/viewmodel/clinician/patient_detail_viewmodel.dart

import 'package:flutter/foundation.dart';

import '../../models/patient_model.dart';
import '../../models/diagnose_model.dart';
import '../../models/light_data_model.dart';
import '../../models/patient_event_model.dart';
import '../../services/services/api_services.dart';
import '../../services/processing/data_processing_manager.dart';

class PatientDetailViewModel extends ChangeNotifier {
  // -------------------------------------------------------
  // 1) API‐futures for patient‐detaljer, diagnoser og aktiviteter
  // -------------------------------------------------------

  final String patientId;

  late final Future<Patient> patientFuture;
  Patient? _patient;
  Patient? get patient => _patient;

  double get rmeqScore => (_patient?.rmeqScore ?? 0).toDouble();
  int? get storedMeqScore => _patient?.meqScore;

  late final Future<List<Diagnosis>> diagnosisFuture;
  late final Future<List<PatientEvent>> patientEventsFuture;

  // -------------------------------------------------------
  // 2) Rå lysdata (LightData) hentet fra API
  // -------------------------------------------------------

  List<LightData> _rawLightData = [];
  List<LightData> get rawLightData => _rawLightData;

  bool _isFetchingRaw = false;
  bool get isFetchingRaw => _isFetchingRaw;

  String? _rawFetchError;
  String? get rawFetchError => _rawFetchError;

  late final Future<void> lightDataFuture;
  Future<void> get getLightDataFuture => lightDataFuture;

  // -------------------------------------------------------
  // 3) ML‐bearbejdning (DataProcessingManager)
  // -------------------------------------------------------

  final DataProcessingManager _dataProcessingManager;

  ProcessedLightData? _processedLightData;
  ProcessedLightData? get processedLightData => _processedLightData;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  // -------------------------------------------------------
  // 4) Konstruktion og initialisering
  // -------------------------------------------------------

  PatientDetailViewModel(this.patientId)
      : _dataProcessingManager = DataProcessingManager() {
    _initFutures();
    lightDataFuture = _fetchRawLightData();
  }

  void _initFutures() {
    patientFuture = ApiService.getPatientDetails(patientId).then((patient) {
      _patient = patient;
      notifyListeners();
      return _patient!;
    });

    diagnosisFuture = ApiService.getPatientDiagnoses(patientId)
        .then((list) => list.map((e) => Diagnosis.fromJson(e)).toList());

    patientEventsFuture = ApiService.fetchActivities(patientId)
        .then((list) => list.map((e) => PatientEvent.fromJson(e)).toList());
  }

  // 🚨 Lysdata-bypass i kDebugMode
  Future<void> _fetchRawLightData() async {
    _isFetchingRaw = true;
    _rawFetchError = null;
    notifyListeners();

    try {
      final String patientIdForLightData = kDebugMode ? 'P3' : patientId;

      if (kDebugMode) {
        debugPrint('⚠️ [DEBUG MODE] Henter lysdata for P3 i stedet for $patientId');
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

  // -------------------------------------------------------
  // 5) ML‐bearbejdning: Kør DataProcessingManager på gårsdagens subset
  // -------------------------------------------------------

  Future<void> _triggerProcessYesterday() async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final midnightToday = DateTime(now.year, now.month, now.day);
      final yesterdayMidnight = midnightToday.subtract(const Duration(days: 1));
      final yesterdayEnd = midnightToday.subtract(const Duration(seconds: 1));

      final List<LightData> yesterdayData = _rawLightData.where((entry) {
        final dtLocal = entry.capturedAt.toLocal();
        return dtLocal.isAfter(yesterdayMidnight.subtract(const Duration(milliseconds: 1))) &&
            dtLocal.isBefore(yesterdayEnd.add(const Duration(milliseconds: 1)));
      }).toList();

      if (yesterdayData.isEmpty) {
        _error = 'Ingen lysdata fra i går';
        _processedLightData = null;
      } else {
        final List<double> inputVector = yesterdayData.map((e) => e.ediLux).toList();
        final processedResult = await _dataProcessingManager.runProcessData(inputVector);

        if (processedResult != null) {
          _processedLightData = ProcessedLightData(
            timestamp: DateTime.now(),
            medi: processedResult.medi,
            fThreshold: processedResult.fThreshold,
            mediDuration: processedResult.mediDuration,
          );
        } else {
          _processedLightData = null;
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

  Future<void> refreshProcessedData() async {
    await _triggerProcessYesterday();
  }
}
