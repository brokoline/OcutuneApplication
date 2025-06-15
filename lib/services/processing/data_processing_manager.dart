// lib/services/processing/data_processing_manager.dart

import 'package:flutter/foundation.dart';
import 'data_processing.dart';

// Resultatmodel til UI m.m.
class ProcessedLightData {
  final DateTime timestamp;
  final double medi;
  final double fThreshold;
  final Duration mediDuration;

  ProcessedLightData({
    required this.timestamp,
    required this.medi,
    required this.fThreshold,
    required this.mediDuration,
  });
}

// Manageren
class DataProcessingManager extends ChangeNotifier {
  DataProcessing? _dataProcessing;
  dynamic _activeProfile; // Kan være Patient eller Customer

  ProcessedLightData? _latestProcessed;
  ProcessedLightData? get latestProcessed => _latestProcessed;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  // Initialisér med en profil (Patient eller Customer).
  // Skal kaldes når bruger vælges eller logger ind
  Future<void> setProfile(dynamic profile) async {
    _activeProfile = profile;
    final int rmeq = profile.rmeqScore;
    _dataProcessing = DataProcessing(true, rmeq);
    await _dataProcessing!.initializeMatrices();
    notifyListeners();
  }

  // Geninitialiser DataProcessing hvis du skifter profil
  void disposeModel() {
    _dataProcessing?.close();
    _dataProcessing = null;
    _activeProfile = null;
    notifyListeners();
  }

  // Kør data-processing workflow
  Future<ProcessedLightData?> runProcessData(List<double> inputVector) async {
    if (_dataProcessing == null) {
      _error = "Ingen aktiv profil valgt!";
      notifyListeners();
      return null;
    }
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _dataProcessing!.processData(inputVector);

      final output = ProcessedLightData(
        timestamp: DateTime.now(),
        medi: result.medi,
        fThreshold: result.fThreshold,
        mediDuration: result.mediDuration,
      );

      _latestProcessed = output;
      return output;
    } catch (e) {
      _error = 'Fejl under ML-behandling: $e';
      _latestProcessed = null;
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Let adgang til aktiv profil (navn og rmeqScore)
  String get activeProfileName =>
      _activeProfile != null ? _activeProfile.fullName : '';
  int? get activeRmeqScore =>
      _activeProfile?.rmeqScore;
}
