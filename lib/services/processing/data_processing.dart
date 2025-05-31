import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/operations.dart';


class DataProcessing {
  Interpreter? _interpreter;
  bool _modelLoaded = false;

  /// Erstat med de korrekte offset‐værdier fra din vejleder.
  static const List<double> offsetCorrection = [
    0.0, 0.0, 0.0, /* … fyld ud … */
  ];

  Future<void> loadModel(String modelAssetPath) async {
    if (_modelLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _modelLoaded = true;
    } catch (e) {
      print('Fejl ved indlæsning af ML-model: $e');
      rethrow;
    }
  }


  void close() {
    _interpreter?.close();
    _modelLoaded = false;
  }

  /// Kør ML‐inference ved hjælp af Interpreter.run(...) i stedet for TensorBuffer.
  /// - [inputVector] skal være en List<double> med præcis `N` elementer.
  /// - Returnerer en List<double> med `M` elementer, råt output fra modellen.
  List<double> runModel(List<double> inputVector) {
    if (!_modelLoaded || _interpreter == null) {
      throw StateError('ML-model ikke loaded. Kald loadModel() først.');
    }

    // Hent shapes
    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    final inputShape = inputTensor.shape;   // fx [1, N]
    final outputShape = outputTensor.shape; // fx [1, M]

    // Tjek, at inputVector matcher modelkravet (N)
    final expectedInputElements = inputShape.reduce((a, b) => a * b);
    if (inputVector.length != expectedInputElements) {
      throw ArgumentError(
          'Input længde (${inputVector.length}) matcher ikke modelkrav ($expectedInputElements).'
      );
    }

    // Byg “indpakning” for TFLite: en List<List<double>>
    // Hvis inputShape er [1, N], så giver vi modellen en 2D‐liste: [[x1, x2, …, xN]]
    final List<List<double>> inputWrapper = [inputVector];

    // Forbered output‐container: en 2D‐liste med samme struktur [1, M]
    final outputLength = outputShape.reduce((a, b) => a * b);
    final List<List<double>> outputWrapper = [List<double>.filled(outputLength, 0.0)];

    // Kør modellen
    _interpreter!.run(inputWrapper, outputWrapper);

    // Hent output: outputWrapper[0] er en List<double> af længde M
    return outputWrapper[0];
  }

  /// Juster model‐output med offset‐listen.
  List<double> applyOffsetCorrection(List<double> rawOutput) {
    if (offsetCorrection.length != rawOutput.length) {
      throw ArgumentError(
          'offsetCorrection længde (${offsetCorrection.length}) matcher ikke output‐længde (${rawOutput.length}).'
      );
    }
    return List.generate(rawOutput.length, (i) => rawOutput[i] + offsetCorrection[i]);
  }

  /// Eksempel på MEDI‐beregning (kan tilpasses jeres rigtige formel).
  double calculateMedi(List<double> correctedOutput) {
    return Operations.mean(correctedOutput);
  }

  /// Eksempel på f‐threshold‐beregning (kan tilpasses jeres rigtige formel).
  double calculateFThreshold(List<double> correctedOutput, double threshold) {
    final countAbove = correctedOutput.where((v) => v >= threshold).length;
    return countAbove / correctedOutput.length;
  }

  /// Konverterer en metrisk værdi (f.eks. en brøk 0.0–1.0) til en Duration (timer+minutter).
  Duration convertDoubleToDuration(double metricValue) {
    final totalSeconds = (metricValue * 24 * 3600).round();
    return Duration(seconds: totalSeconds);
  }

  /// Fuldt workflow: fra rå input til endelige metrikker.
  Future<ProcessedResult> processData(List<double> rawInput) async {
    // 1) Normaliser rådata, hvis nødvendigt
    final normalized = Operations.normalizeVector(rawInput);

    // 2) Kør ML‐model
    final modelOutput = runModel(normalized);

    // 3) Tilpas med offset
    final corrected = applyOffsetCorrection(modelOutput);

    // 4) Beregn metrikker
    final medi = calculateMedi(corrected);
    final fThresh = calculateFThreshold(corrected, 0.5); // 0.5 er bare et eksempel

    // 5) Konverter til Duration
    final mediDuration = convertDoubleToDuration(medi);

    return ProcessedResult(
      rawOutput: modelOutput,
      correctedOutput: corrected,
      medi: medi,
      fThreshold: fThresh,
      mediDuration: mediDuration,
    );
  }
}

/// Model til at pakke resultaterne sammen
class ProcessedResult {
  final List<double> rawOutput;
  final List<double> correctedOutput;
  final double medi;
  final double fThreshold;
  final Duration mediDuration;

  ProcessedResult({
    required this.rawOutput,
    required this.correctedOutput,
    required this.medi,
    required this.fThreshold,
    required this.mediDuration,
  });
}
