import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

// Til normalisering og mean
class Operations {
  static List<double> normalizeVector(List<double> v) {
    double maxVal = v.reduce(max);
    return v.map((e) => e / (maxVal == 0 ? 1 : maxVal)).toList();
  }

  static double mean(List<double> v) =>
      v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length;
}

// Resultat-model
class ProcessedResult {
  final List<double> spectrum;
  final double melanopic;
  final double illuminance;
  final double medi;
  final double fThreshold;
  final Duration mediDuration;

  ProcessedResult({
    required this.spectrum,
    required this.melanopic,
    required this.illuminance,
    required this.medi,
    required this.fThreshold,
    required this.mediDuration,
  });
}

class DataProcessing {
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _matricesLoaded = false;

  // --- Matrixfiler og korrektioner ---
  late final List<List<double>> M0, M1, M2, M3, M4, M5, M6;
  late final List<List<double>> cieCmf1931, alphaOpic;
  List<double> yBar = List.filled(401, 0.0);
  List<double> mediArr = List.filled(401, 0.0);

  // Til 8-kanals data
  static const List<double> offsetCorrection = [
    0.00197, 0.00725, 0.00319, 0.00131,
    0.00147, 0.00186, 0.00176, 0.00522
  ];
  static const List<double> factorCorrection = [
    1.02811, 1.03149, 1.03142, 1.03125,
    1.03390, 1.03445, 1.03508, 1.03359
  ];

  // ML-model load
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

  // CSV-loader
  Future<List<List<double>>> parseCsvFileToMatrix(String path) async {
    final data = await rootBundle.loadString(path);
    final lines = LineSplitter.split(data);
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) =>
        line.split(',').map((e) => double.tryParse(e.trim()) ?? 0.0).toList())
        .toList();
  }

  // Initialiserer og læser alle matricefiler
  Future<void> initializeMatrices() async {
    M0 = await parseCsvFileToMatrix('assets/matrices/matrixdaylight_8.csv');
    M1 = await parseCsvFileToMatrix('assets/matrices/matrixled_8.csv');
    M2 = await parseCsvFileToMatrix('assets/matrices/matrixmix_8.csv');
    M3 = await parseCsvFileToMatrix('assets/matrices/matrixhalogen_8.csv');
    M4 = await parseCsvFileToMatrix('assets/matrices/matrixfluo_8.csv');
    M5 = await parseCsvFileToMatrix('assets/matrices/matrixfluoday_8.csv');
    M6 = await parseCsvFileToMatrix('assets/matrices/matrixscreenday_8.csv');
    cieCmf1931 = await parseCsvFileToMatrix('assets/matrices/ciecmf1931.csv');
    alphaOpic = await parseCsvFileToMatrix('assets/matrices/alpha_opic.csv');
    for (var i = 0; i < 401; i++) {
      yBar[i] = cieCmf1931[i][1];
      mediArr[i] = alphaOpic[i][4];
    }
    _matricesLoaded = true;
  }

  // Matrix-vector-multiplikation
  List<double> matrixVectorMultiplication(List<List<double>> matrix, List<double> vector) {
    List<double> result = List.filled(matrix.length, 0.0);
    for (int i = 0; i < matrix.length; i++) {
      double sum = 0.0;
      for (int j = 0; j < vector.length; j++) {
        sum += matrix[i][j] * vector[j];
      }
      result[i] = sum;
    }
    return result;
  }

  // Hele spektre-workflowet
  Future<List<double>> getSpectrum(
      List<double> channels, double astep, double again) async {
    if (!_matricesLoaded) throw Exception('Matricer ikke initialiseret');
    if (!_modelLoaded || _interpreter == null) {
      throw StateError('ML-model ikke loaded. Kald loadModel() først.');
    }

    double inter = astep * 29 * 2.78 * 0.001;
    double gainR = pow(2.0, again - 1.0).toDouble();

    List<double> basicCounts = List.filled(8, 0.0);
    List<double> correctedData = List.filled(8, 0.0);

    for (int i = 0; i < channels.length; i++) {
      basicCounts[i] = channels[i] / (inter * gainR);
    }

    for (int i = 0; i < channels.length; i++) {
      correctedData[i] =
          factorCorrection[i] * (basicCounts[i] - offsetCorrection[i]);
    }

    // ML model input skal være [1][8][1]
    var input = List<List<List<double>>>.generate(
        1,
            (_) => List<List<double>>.generate(
            8, (i) => [correctedData[i]]
        )
    );

    var output = List.generate(1, (i) => List.filled(7, 0.0));
    _interpreter!.run(input, output);
    List<double> outputValues = output[0];
    int maxIndex = outputValues.indexWhere((e) => e == outputValues.reduce(max));
    List<double> spectrum = List.filled(401, 0.0);

    switch (maxIndex) {
      case 0:
        spectrum = matrixVectorMultiplication(M0, correctedData);
        break;
      case 1:
        spectrum = matrixVectorMultiplication(M1, correctedData);
        break;
      case 2:
        spectrum = matrixVectorMultiplication(M2, correctedData);
        break;
      case 3:
        spectrum = matrixVectorMultiplication(M3, correctedData);
        break;
      case 4:
        if (correctedData[7] > correctedData[6] / 2) {
          spectrum = matrixVectorMultiplication(M1, correctedData);
        } else {
          spectrum = matrixVectorMultiplication(M4, correctedData);
        }
        break;
      case 5:
        spectrum = matrixVectorMultiplication(M5, correctedData);
        break;
      case 6:
        spectrum = matrixVectorMultiplication(M6, correctedData);
        break;
    }
    return spectrum;
  }

  // Melanopic illuminance
  double melanopic(List<double> spectrum) {
    double normConst = 1.3262 / 1000;
    double medi = dotProduct(spectrum, mediArr) / normConst;
    return medi;
  }

  // Illuminance
  double illuminance(List<double> spectrum) {
    double Y = dotProduct(spectrum, yBar);
    double E = Y * 683; // Konvertering
    return E;
  }

  // Helper: Dot product
  double dotProduct(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  // Threshold-metode og mean-metode
  double calculateMedi(List<double> correctedOutput) =>
      Operations.mean(correctedOutput);

  double calculateFThreshold(List<double> correctedOutput, double threshold) {
    final countAbove = correctedOutput.where((v) => v >= threshold).length;
    return countAbove / correctedOutput.length;
  }

  Duration convertDoubleToDuration(double metricValue) {
    final totalSeconds = (metricValue * 24 * 3600).round();
    return Duration(seconds: totalSeconds);
  }

  // Fuldt workflow: Fra kanaler til metrikker
  Future<ProcessedResult> processDataWorkflow({
    required List<double> rawChannels, // typisk 8 værdier fra sensor
    required double astep,
    required double again,
  }) async {
    // (1) Lav spektre
    final spectrum = await getSpectrum(rawChannels, astep, again);

    // (2) Beregn melanopic og illuminance
    final mediVal = melanopic(spectrum);
    final illumVal = illuminance(spectrum);

    // (4) Mean/fThreshold og konverterer til duration
    final medi = calculateMedi(spectrum);
    final fThresh = calculateFThreshold(spectrum, 0.5);
    final mediDuration = convertDoubleToDuration(medi);

    return ProcessedResult(
      spectrum: spectrum,
      melanopic: mediVal,
      illuminance: illumVal,
      medi: medi,
      fThreshold: fThresh,
      mediDuration: mediDuration,
    );
  }

  Future<ProcessedResult> processData(List<double> inputVector) async {
    if (inputVector.length < 10) {
      throw ArgumentError("inputVector skal mindst indeholde 10 værdier (8 kanaler + astep + again)");
    }
    final channels = inputVector.sublist(0, 8);
    final astep = inputVector[8];
    final again = inputVector[9];
    return await processDataWorkflow(
      rawChannels: channels,
      astep: astep,
      again: again,
    );
  }

}
