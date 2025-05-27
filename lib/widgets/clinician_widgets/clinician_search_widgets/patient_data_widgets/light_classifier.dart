import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class LightClassifier {
  late final Interpreter _interpreter;

  LightClassifier._(this._interpreter);

  static Future<LightClassifier> create() async {
    try {
      final byteData = await rootBundle.load('assets/classifier.tflite');
      final buffer = byteData.buffer;
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/classifier.tflite';
      final file = File(modelPath);
      await file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );

      final interpreter = Interpreter.fromFile(file);

      print("✅ Interpreter oprettet fra: $modelPath");
      print("📐 Input shape: ${interpreter.getInputTensor(0).shape}");
      print("📐 Output shape: ${interpreter.getOutputTensor(0).shape}");

      return LightClassifier._(interpreter);
    } catch (e) {
      print("❌ Fejl ved oprettelse af LightClassifier: $e");
      rethrow;
    }
  }

  int classify(List<double> input) {
    const expectedLength = 8;

    if (input.length != expectedLength) {
      input = List<double>.from(input.take(expectedLength))
        ..addAll(List.filled(expectedLength - input.length, 0.0));
    }

    final inputTensor = [input.map((e) => [e]).toList()];
    final outputTensor = List.generate(1, (_) => List.filled(7, 0.0));

    try {
      _interpreter.run(inputTensor, outputTensor);
    } catch (e) {
      print("❌ Fejl under modelkørsel: $e");
      rethrow;
    }

    final prediction = outputTensor[0];
    final maxValue = prediction.reduce((a, b) => a > b ? a : b);
    final maxIndex = prediction.indexOf(maxValue);

    print("📊 Klassificering: input=$input → prediction=$prediction → class=$maxIndex");

    return maxIndex;
  }

  static Future<List<List<double>>> loadRegressionMatrix() async {
    try {
      final csv = await rootBundle.loadString('assets/regression_matrix.csv');
      final matrix = LineSplitter.split(csv)
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) =>
          line.split(',').map((e) => double.tryParse(e.trim()) ?? 0.0).toList())
          .toList();

      print("📄 Indlæst regression_matrix med ${matrix.length} rækker, hver med ${matrix[0].length} værdier");
      return matrix;
    } catch (e) {
      print("❌ Fejl ved indlæsning af regression_matrix.csv: $e");
      rethrow;
    }
  }

  static List<double> reconstructSpectrum(List<double> input, List<double> weights) {
    final inputLength = input.length;
    final weightLength = weights.length;

    if (weightLength % inputLength != 0) {
      throw Exception("❌ Vægtlængde ($weightLength) skal være et multiplum af input-længde ($inputLength).");
    }

    final bandsPerInput = weightLength ~/ inputLength;
    final reconstructed = List<double>.filled(weightLength, 0.0);

    for (int i = 0; i < weightLength; i++) {
      final inputIndex = i ~/ bandsPerInput;
      reconstructed[i] = input[inputIndex] * weights[i];
    }

    print("🔧 Rekonstrueret spektrum (${reconstructed.length} værdier) fra input=$input");

    return reconstructed;
  }

  static Future<List<double>> loadCurve(String path) async {
    try {
      final content = await rootBundle.loadString(path);
      final values = LineSplitter.split(content)
          .expand((line) => line.split(','))
          .map((e) => double.tryParse(e.trim()))
          .whereType<double>()
          .toList();

      print("📈 Indlæst kurve fra $path med ${values.length} værdier");

      return values;
    } catch (e) {
      print("❌ Fejl ved indlæsning af kurve fra $path: $e");
      rethrow;
    }
  }

  /// Interpolér en kurve til samme længde som spektrum
  static List<double> _resampleCurve(List<double> curve, int targetLength) {
    final List<double> resampled = List.filled(targetLength, 0.0);
    final double factor = (curve.length - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; i++) {
      final double index = i * factor;
      final int low = index.floor();
      final int high = index.ceil();

      if (low == high) {
        resampled[i] = curve[low];
      } else {
        final double t = index - low;
        resampled[i] = curve[low] * (1 - t) + curve[high] * t;
      }
    }

    print("🔁 Resamplet kurve fra ${curve.length} → $targetLength");
    return resampled;
  }

  static double calculateMelanopicEDI(List<double> spectrum, List<double> melanopicCurve) {
    const melanopicConstant = 1.3262;

    // Brug resampling hvis nødvendigt
    final curve = (spectrum.length == melanopicCurve.length)
        ? melanopicCurve
        : _resampleCurve(melanopicCurve, spectrum.length);

    double sum = 0.0;
    for (int i = 0; i < spectrum.length; i++) {
      sum += spectrum[i] * curve[i];
    }

    final edi = sum / melanopicConstant;
    print("☀️ Melanopic EDI: $edi");
    return edi;
  }

  static double calculateIlluminance(List<double> spectrum, List<double> yBar) {
    const K = 683.0;

    // Brug resampling hvis nødvendigt
    final curve = (spectrum.length == yBar.length)
        ? yBar
        : _resampleCurve(yBar, spectrum.length);

    double sum = 0.0;
    for (int i = 0; i < spectrum.length; i++) {
      sum += spectrum[i] * curve[i];
    }

    final lux = sum * K;
    print("💡 Illuminance (Lux): $lux");
    return lux;
  }
}
