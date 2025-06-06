// lib/controllers/processed_data_controller.dart

import 'package:flutter/foundation.dart';
import 'data_processing_manager.dart';

/// Controller der styrer ML‐flowet via [DataProcessingManager].
/// Nu accepterer vi en liste af double‐værdier (f.eks. gårsdagens ediLux),
/// kalder [runProcessData] og gemmer resultatet i [_latestProcessed].
class ProcessedDataController extends ChangeNotifier {
  final DataProcessingManager _manager;
  ProcessedLightData? _latestProcessed;

  ProcessedLightData? get latestProcessed => _latestProcessed;

  ProcessedDataController(this._manager);

  /// Kør ML‐flowet på den givne liste af double‐værdier (inputVector).
  /// Eksempelvis kan [inputVector] være ediLux‐værdier for gårsdagens lysmålinger.
  Future<void> refreshProcessedData(List<double> inputVector) async {
    _latestProcessed = await _manager.runProcessData(inputVector);
    notifyListeners();
  }
}
