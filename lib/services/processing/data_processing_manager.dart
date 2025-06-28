import 'package:flutter/foundation.dart';
import 'data_processing.dart';

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

class DataProcessingManager extends ChangeNotifier {
  DataProcessing? _dataProcessing;
  dynamic _activeProfile;

  ProcessedLightData? _latestProcessed;
  ProcessedLightData? get latestProcessed => _latestProcessed;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  Future<void> setProfile(dynamic profile) async {
    _activeProfile = profile;
    final int rmeq = profile.rmeqScore;
    _dataProcessing = DataProcessing(true, rmeq);
    await _dataProcessing!.initializeMatrices();
    notifyListeners();
  }

  void disposeModel() {
    _dataProcessing?.close();
    _dataProcessing = null;
    _activeProfile = null;
    notifyListeners();
  }

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
      _error = 'Fejl under databehandling: $e';
      _latestProcessed = null;
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String get activeProfileName =>
      _activeProfile != null ? _activeProfile.fullName : '';
  int? get activeRmeqScore =>
      _activeProfile?.rmeqScore;
}
