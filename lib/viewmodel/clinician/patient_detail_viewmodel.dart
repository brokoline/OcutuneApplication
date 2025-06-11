// lib/viewmodel/clinician/patient_detail_viewmodel.dart

import 'package:flutter/foundation.dart';

import '../../models/patient_model.dart';
import '../../models/diagnose_model.dart';
import '../../models/light_data_model.dart';
import '../../models/patient_event_model.dart';
import '../../services/processing/data_processing.dart';
import '../../services/services/api_services.dart';
import '../../services/processing/data_processing_manager.dart';

/// PatientDetailViewModel kombinerer:
///  1) API‐Futures til patientoplysninger, diagnoser og aktiviteter.
///  2) Hent af rå lysdata fra backend via API (getPatientLightData).
///  3) ML‐bearbejdning af gårsdagens lysdata (DataProcessingManager).
///

class PatientDetailViewModel extends ChangeNotifier {
  // -------------------------------------------------------
  // 1) API‐futures for patient‐detaljer, diagnoser og aktiviteter
  // -------------------------------------------------------

  final String patientId;

  // Fremtid som henter Patient‐objektet
  late final Future<Patient> patientFuture;

  // Gemmer den hentede Patient‐instans
  Patient? _patient;
  Patient? get patient => _patient;

  // Offentlig getter til rMEQ‐score (kort version). Returnerer 0 hvis ikke tilgængelig.
  double get rmeqScore => (_patient?.rmeqScore ?? 0).toDouble();

  // Offentlig getter til gemt MEQ‐score (lang version). Kan være null, hvis patienten ikke har udfyldt MEQ‐spørgeskemaet.
  int? get storedMeqScore => _patient?.meqScore;

  // Fremtid som henter alle diagnoser for patienten
  late final Future<List<Diagnosis>> diagnosisFuture;

  /// Fremtid som henter alle patient‐aktiviteter
  late final Future<List<PatientEvent>> patientEventsFuture;


  // -------------------------------------------------------
  // 2) Rå lysdata (LightData) hentet fra API
  // -------------------------------------------------------

  /// Den komplette liste af lysdata for denne patient (fra backend)
  List<LightData> _rawLightData = [];
  List<LightData> get rawLightData => _rawLightData;

  /// Flag for om rå‐lysdata er ved at blive hentet
  bool _isFetchingRaw = false;
  bool get isFetchingRaw => _isFetchingRaw;

  String? _rawFetchError;
  String? get rawFetchError => _rawFetchError;

  /// Gemmer Future, så UI kan lave en FutureBuilder på [lightDataFuture]
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
      : _dataProcessingManager = DataProcessingManager(
    dataProcessing: DataProcessing(),
  ) {
    // a) Opsæt alle de “Future”-felter og gem Patient
    _initFutures();

    // b) Indlæs TFLite‐modellen asynkront
    _dataProcessingManager.initializeModel();

    // c) Hent rå lysdata fra API (gem Future i feltet)
    lightDataFuture = _fetchRawLightData();
  }

  /// Opretter og gemmer patientFuture, diagnosisFuture og patientEventsFuture.
  void _initFutures() {
    // 1) Hent Patient og gem i _patient (antager, at getPatientDetails returnerer en Patient)
    patientFuture =
        ApiService.getPatientDetails(patientId).then((patient) {
          _patient = patient;
          // Notify, så UI kan læse rmeqScore + storedMeqScore
          notifyListeners();
          return _patient!;
        });

    // 2) Diagnoser‐future
    diagnosisFuture = ApiService.getPatientDiagnoses(patientId)
        .then((list) => list.map((e) => Diagnosis.fromJson(e)).toList());

    // 3) Aktivitets‐future
    patientEventsFuture = ApiService.fetchActivities(patientId)
        .then((list) => list.map((e) => PatientEvent.fromJson(e)).toList());
  }

  // Internt kald til at hente alle LightData for denne patient fra backend.
  // Returnerer en Future void, så UI kan bruge en FutureBuilder på [lightDataFuture].
  Future<void> _fetchRawLightData() async {
    _isFetchingRaw = true;
    _rawFetchError = null;
    notifyListeners();

    try {
      final list = await ApiService.getPatientLightData(patientId);
      // Konverter JSON → LightData‐objekter
      final rawList = list.map((e) => LightData.fromJson(e)).toList();
      _rawLightData = rawList;
      _isFetchingRaw = false;
      notifyListeners();

      // Kør straks ML‐bearbejdning for gårsdagens subset
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
    // Luk og frigiv TFLite‐model
    _dataProcessingManager.disposeModel();
    super.dispose();
  }


  // -------------------------------------------------------
  // 5) ML‐bearbejdning: Kør DataProcessingManager på “gårsdagens” subset
  // -------------------------------------------------------

  /// Filtrér “i går”s lysdata fra _rawLightData og kald DataProcessingManager.
  Future<void> _triggerProcessYesterday() async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final midnightToday = DateTime(now.year, now.month, now.day);
      final yesterdayMidnight = midnightToday.subtract(const Duration(days: 1));
      final yesterdayEnd =
      midnightToday.subtract(const Duration(seconds: 1));

      final List<LightData> yesterdayData = _rawLightData.where((entry) {
        // Brug .toLocal() i tilfælde af, at entry.capturedAt er UTC
        final dtLocal = entry.capturedAt.toLocal();
        return dtLocal.isAfter(
            yesterdayMidnight.subtract(const Duration(milliseconds: 1))) &&
            dtLocal.isBefore(
                yesterdayEnd.add(const Duration(milliseconds: 1)));
      }).toList();

      if (yesterdayData.isEmpty) {
        _error = 'Ingen lysdata fra i går';
        _processedLightData = null;
      } else {
        // Konverter til List<double> ved brug af ediLux
        final List<double> inputVector =
        yesterdayData.map((e) => e.ediLux).toList();

        // Kør ML‐flowet
        final processedResult =
        await _dataProcessingManager.runProcessData(inputVector);

        // Pak resultatet ind i ProcessedLightData
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

  /// Ekstern metode, som UI evt. kan kalde (f.eks. ved knaptryk) for manuelt at
  /// genudløse “kør ML på gårsdagens lysdata”.
  Future<void> refreshProcessedData() async {
    await _triggerProcessYesterday();
  }
}
