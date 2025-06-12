// lib/services/processing/data_processing_manager.dart

import 'package:flutter/foundation.dart';
import 'data_processing.dart';


class ProcessedLightData {
  // Tidspunkt (DateTime.now())
  final DateTime timestamp;

  // Beregnet MEDI-værdi ud fra ML-output + offsetkorrektion.
  final double medi;

  // Beregnet f-threshold: andel af værdier over en tærskel.
  final double fThreshold;

  // MEDI omsat til en Duration (timer + minutter).
  final Duration mediDuration;

  ProcessedLightData({
    required this.timestamp,
    required this.medi,
    required this.fThreshold,
    required this.mediDuration,
  });
}

// DataProcessingManager er ansvarlig for at
// 1) Loade TFLite-modellen (via DataProcessing)
// 2) Køre ML-inference på en given liste af double (seneste dags lysdata)
// 3) Returnere resultatet pakket ind i [ProcessedLightData]
class DataProcessingManager extends ChangeNotifier {
  final DataProcessing _dataProcessing;

  // Senest kørte ML-resultat (eller null, hvis ikke kørt endnu).
  ProcessedLightData? _latestProcessed;
  ProcessedLightData? get latestProcessed => _latestProcessed;

  // Flag, der indikerer, om manageren er ved at behandle data lige nu.
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // Eventuel fejlbesked (fx “ingen data” eller exception under ML).
  String? _error;
  String? get error => _error;

  DataProcessingManager({
    required DataProcessing dataProcessing,
  }) : _dataProcessing = dataProcessing;

  // Initialiserer og loade TFLite-modellen fra assets (kalds i ViewModel/konstruktør).
  Future<void> initializeModel() async {
    const modelAssetPath = 'assets/classifier.tflite';
    try {
      await _dataProcessing.loadModel(modelAssetPath);
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
      rethrow;
    }
  }

  // Lukker og frigiver ressourcer for TFLite-interpreteren
  void disposeModel() {
    _dataProcessing.close();
  }

  // Kører ML-inference på [inputVector] (liste af double-værdier) og returner et [ProcessedLightData].
  Future<ProcessedLightData?> runProcessData(List<double> inputVector) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // 1) Kør DataProcessing‐flowet: normalisering, ML, offsetkorrektion, metrikker
      final result = await _dataProcessing.processData(inputVector);

      // 2) Pakker til modelklasse
      final output = ProcessedLightData(
        timestamp: DateTime.now(),
        medi: result.medi,
        fThreshold: result.fThreshold,
        mediDuration: result.mediDuration,
      );

      // 3) Notificérer UI
      _latestProcessed = output;
      return output;
    } catch (e) {
      // Hvis noget går galt under ML, gemmer fejlbesked
      _error = 'Fejl under ML-behandling: $e';
      _latestProcessed = null;
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
