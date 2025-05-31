// lib/services/processing/data_processing_manager.dart

import 'package:flutter/foundation.dart';

import 'data_processing.dart';

/// Model til at opbevare resultaterne for én dags ML-kørsel.
/// Udvid eventuelt med flere felter (fx rå output-lister, DLMO-tidspunkt).
class ProcessedLightData {
  /// Tidspunkt (DateTime.now()), hvor vi kørte ML-flowet.
  final DateTime timestamp;

  /// Beregnet MEDI-værdi ud fra ML-output + offsetkorrektion.
  final double medi;

  /// Beregnet f-threshold: andel af værdier over en tærskel.
  final double fThreshold;

  /// MEDI omsat til en Duration (timer + minutter).
  final Duration mediDuration;

  ProcessedLightData({
    required this.timestamp,
    required this.medi,
    required this.fThreshold,
    required this.mediDuration,
  });
}

/// DataProcessingManager er ansvarlig for at
/// 1) Loade TFLite-modellen (via DataProcessing)
/// 2) Køre ML-inference på en given liste af double (sidste dags lysdata)
/// 3) Returnere resultatet pakket ind i [ProcessedLightData]
///
/// Vi fjerner afhængigheden af LightDataController her,
/// da vi i ViewModel nu selv filtrerer “i går”s data og sender dem som List<double>.
class DataProcessingManager extends ChangeNotifier {
  final DataProcessing _dataProcessing;

  /// Senest kørte ML-resultat (eller null, hvis ikke kørt endnu).
  ProcessedLightData? _latestProcessed;
  ProcessedLightData? get latestProcessed => _latestProcessed;

  /// Flag, der indikerer, om manageren er ved at behandle data lige nu.
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Eventuel fejlbesked (fx “ingen data” eller exception under ML).
  String? _error;
  String? get error => _error;

  DataProcessingManager({
    required DataProcessing dataProcessing,
  }) : _dataProcessing = dataProcessing;

  /// Initialiserer og loade TFLite-modellen fra assets (kalds f.eks. i ViewModel/konstruktør).
  Future<void> initializeModel() async {
    const modelAssetPath = 'assets/classifier.tflite';
    try {
      await _dataProcessing.loadModel(modelAssetPath);
    } catch (e) {
      // Hvis modellen ikke kan indlæses, kan du fange fejlen her
      debugPrint('Error loading TFLite model: $e');
      rethrow;
    }
  }

  /// Lukker og frigiver ressourcer for TFLite-interpreteren (kalds i ViewModel.dispose()).
  void disposeModel() {
    _dataProcessing.close();
  }

  /// Kør ML-inference på [inputVector] (liste af double-værdier) og returner et [ProcessedLightData].
  ///
  /// [inputVector] bør være én dags worth af målte lysværdier (fx ediLux fra i går).
  /// Vi sætter _isProcessing true, sætter eventuelt _error til null, og notiferer lyttere.
  Future<ProcessedLightData?> runProcessData(List<double> inputVector) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // 1) Kør DataProcessing‐flowet: normalisering, ML, offsetkorrektion, metrikker
      final result = await _dataProcessing.processData(inputVector);

      // 2) Pak til vores egen modelklasse
      final output = ProcessedLightData(
        timestamp: DateTime.now(),
        medi: result.medi,
        fThreshold: result.fThreshold,
        mediDuration: result.mediDuration,
      );

      // 3) Gem det seneste, notificér UI
      _latestProcessed = output;
      return output;
    } catch (e) {
      // Hvis noget går galt under ML, gem fejlbeskeden
      _error = 'Fejl under ML-behandling: $e';
      _latestProcessed = null;
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
