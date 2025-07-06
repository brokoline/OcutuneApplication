import 'dart:async';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/operations.dart';

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
  bool customize;
  int? rMEQ;

  DataProcessing(this.customize, [this.rMEQ]);
  double? slb, elb, ss, es, dlmo;

  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _matricesLoaded = false;

  late final List<List<double>> m0, m1, m2, m3, m4, m5, m6;
  late final List<List<double>> cieCmf1931, alphaOpic;
  List<double> yBar = List.filled(401, 0.0);
  List<double> mediArr = List.filled(401, 0.0);

  static const List<double> offsetCorrection = [
    0.00197, 0.00725, 0.00319, 0.00131,
    0.00147, 0.00186, 0.00176, 0.00522, 0.003, 0.001
  ];
  static const List<double> factorCorrection = [
    1.02811, 1.03149, 1.03142, 1.03125,
    1.03390, 1.03445, 1.03508, 1.03359, 1.23384, 1.26942
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

  Future<void> initializeMatrices() async {
    m0 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixdaylight_8.csv');
    m1 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixled_8.csv');
    m2 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixmix_8.csv');
    m3 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixhalogen_8.csv');
    m4 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixfluo_8.csv');
    m5 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixfluoday_8.csv');
    m6 = await Operations.parseCsvFileToMatrix('assets/matrices/matrixscreenday_8.csv');
    cieCmf1931 = await Operations.parseCsvFileToMatrix('assets/matrices/ciecmf1931.csv');
    alphaOpic = await Operations.parseCsvFileToMatrix('assets/matrices/alpha_opic.csv');
    for (var i = 0; i < 401; i++) {
      yBar[i] = cieCmf1931[i][1];
      mediArr[i] = alphaOpic[i][4];
    }
    _matricesLoaded = true;
  }

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

    var input = List<List<List<double>>>.generate(
        1, (_) => List<List<double>>.generate(8, (i) => [correctedData[i]]));

    var output = List.generate(1, (i) => List.filled(7, 0.0));
    _interpreter!.run(input, output);
    List<double> outputValues = output[0];
    int maxIndex = outputValues.indexWhere((e) => e == outputValues.reduce(max));
    List<double> spectrum = List.filled(401, 0.0);

    switch (maxIndex) {
      case 0:
        spectrum = Operations.multiplyMatrixVector(m0, correctedData);
        break;
      case 1:
        spectrum = Operations.multiplyMatrixVector(m1, correctedData);
        break;
      case 2:
        spectrum = Operations.multiplyMatrixVector(m2, correctedData);
        break;
      case 3:
        spectrum = Operations.multiplyMatrixVector(m3, correctedData);
        break;
      case 4:
        if (correctedData[7] > correctedData[6] / 2) {
          spectrum = Operations.multiplyMatrixVector(m1, correctedData);
        } else {
          spectrum = Operations.multiplyMatrixVector(m4, correctedData);
        }
        break;
      case 5:
        spectrum = Operations.multiplyMatrixVector(m5, correctedData);
        break;
      case 6:
        spectrum = Operations.multiplyMatrixVector(m6, correctedData);
        break;
    }
    return spectrum;
  }

  double dotProduct(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  Future<double> melanopic(List<double> spectrum) async {
    double medi = dotProduct(spectrum, mediArr) / (1.3262 / 1000);
    return medi;
  }

  Future<double> illuminance(List<double> spectrum) async {
    double Y = dotProduct(spectrum, yBar);
    double E = Y * 683;
    return E;
  }

  Future<double> der(List<double> spectrum) async {
    double medi = await melanopic(spectrum);
    double lux = await illuminance(spectrum);
    return medi / lux;
  }

  (bool, double) lightExposure(double medi) {
    if (customize == true) {
      return customLightExposure(medi);
    } else {
      return originalLightExposure(medi);
    }
  }

  (bool, double) originalLightExposure(double medi) {
    int hour = DateTime.now().hour;
    double percentage = 0.0;
    bool increase = true;

    if (hour >= 7 && hour < 19) {
      percentage = ((medi / 250).clamp(0.0, 1.0)) * 100;
    } else if (hour >= 19 && hour < 23) {
      percentage = ((10 / medi).clamp(0.0, 1.0)) * 100;
      increase = false;
    } else {
      percentage = ((1 / medi).clamp(0.0, 1.0)) * 100;
      increase = false;
    }
    return (increase, percentage.clamp(0.0, 100.0));
  }

  void setCustomTime(int rMEQ) {
    double sleepWindowStart = 22.0;
    double dlmoTime = 20.0;

    slb = sleepWindowStart;
    elb = sleepWindowStart + 1.5;
    dlmo = dlmoTime;
    ss = dlmoTime + 2;
    es = dlmoTime + 10;
  }

  int getTimeFrame(double currentTime) {
    bool isTimeBetween(double currentTime, double startTime, double endTime) {
      if (startTime == endTime) {
        return true;
      } else if (startTime < endTime) {
        return currentTime >= startTime && currentTime < endTime;
      } else {
        return currentTime >= startTime || currentTime < endTime;
      }
    }

    if (isTimeBetween(currentTime, slb!, elb!)) {
      return 0; //"lightboost";
    } else if (isTimeBetween(currentTime, elb!, dlmo!)) {
      return 1; //"daytime";
    } else if (isTimeBetween(currentTime, dlmo!, ss!)) {
      return 2; //"dlmo";
    } else if (isTimeBetween(currentTime, ss!, es!)) {
      return 3; //"sleep";
    } else if (isTimeBetween(currentTime, es!, slb!)) {
      return 1; //"daytime";
    } else {
      return 4; // "Unknown period";
    }
  }

  (bool, double) customLightExposure(double medi) {
    double hour = DateTime.now().hour.toDouble();
    double minute = DateTime.now().minute.toDouble();
    double currentTime = hour + (minute * 0.01);

    int period = getTimeFrame(currentTime);

    switch (period) {
      case 0: //lightboost
        return (true, ((medi / 1316).clamp(0.0, 1.0)) * 100);
      case 1: //daytime
        return (true, ((medi / 250).clamp(0.0, 1.0)) * 100);
      case 2: //DLMO
        if (medi <= 0.0) return (false, 100.0);
        return (false, ((10 / medi).clamp(0.0, 1.0)) * 100);
      case 3: //sleep
        if (medi <= 0.0) return (false, 100.0);
        return (false, ((1 / medi).clamp(0.0, 1.0)) * 100);
      case 4: //error
        return (true, 0.0);
    }
    return (true, 0.0);
  }

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

  Future<ProcessedResult> processDataWorkflow({
    required List<double> rawChannels,
    required double astep,
    required double again,
  }) async {
    final spectrum = await getSpectrum(rawChannels, astep, again);

    final mediVal = await melanopic(spectrum);
    final illumVal = await illuminance(spectrum);

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
