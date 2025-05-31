import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// Operations.dart
/// Hjælpefunktioner til at parse CSV-filer og udføre matrix- og vektoroperationer.
class Operations {
  /// Læs en CSV-fil fra assets (fx 'assets/matrix.csv')
  /// og returner en matrix (List List double).
  static Future<List<List<double>>> parseCsvFileToMatrix(String filePath) async {
    // Load CSV-teksten fra assets
    final raw = await rootBundle.loadString(filePath);
    // Split på linjeskift for at få rækker
    final lines = raw.split(RegExp(r"\r?\n"));
    final List<List<double>> matrix = [];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      // Split på komma eller semikolon eller tab
      final values = line.split(RegExp(r"[;,\t]")).map((e) => e.trim()).toList();
      final row = <double>[];
      for (var cell in values) {
        // Konverter til double; hvis parsing fejler, brug 0.0
        final parsed = double.tryParse(cell.replaceAll('"', '')) ?? 0.0;
        row.add(parsed);
      }
      matrix.add(row);
    }
    return matrix;
  }

  /// Gang en matrix (m x n) med en vektor (n)
  /// Returnerer en vektor af længde m.
  static List<double> multiplyMatrixVector(List<List<double>> matrix, List<double> vector) {
    final nRows = matrix.length;
    if (nRows == 0) return [];
    final nCols = matrix[0].length;
    if (vector.length != nCols) {
      throw ArgumentError('Matrixer og vektor dimensioner stemmer ikke overens.');
    }
    final result = List<double>.filled(nRows, 0.0);
    for (var i = 0; i < nRows; i++) {
      double sum = 0.0;
      for (var j = 0; j < nCols; j++) {
        sum += matrix[i][j] * vector[j];
      }
      result[i] = sum;
    }
    return result;
  }

  /// Normaliser en vektor ved at trække middelværdi fra og dividere med standardafvigelse.
  /// Hvis stdDev er 0, returneres kun vektoren minus mean.
  static List<double> normalizeVector(List<double> vector) {
    final n = vector.length;
    if (n == 0) return [];
    final mean = vector.reduce((a, b) => a + b) / n;
    double sumSquaredDiffs = 0.0;
    for (var v in vector) {
      sumSquaredDiffs += (v - mean) * (v - mean);
    }
    final variance = sumSquaredDiffs / n;
    final stdDev = variance >= 0 ? sqrt(variance) : 0.0;

    if (stdDev == 0) {
      return vector.map((v) => v - mean).toList();
    }
    return vector.map((v) => (v - mean) / stdDev).toList();
  }

  /// Summér alle elementer i en vektor.
  static double sumVector(List<double> vector) {
    return vector.fold(0.0, (prev, element) => prev + element);
  }

  /// Afsnit alle negative værdier til 0.
  static List<double> clipNegativeToZero(List<double> vector) {
    return vector.map((v) => v < 0 ? 0.0 : v).toList();
  }

  /// Giv to vektorer af samme længde, gang dem elementvis og returner en ny vektor.
  static List<double> multiplyElementWise(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) {
      throw ArgumentError('Vektorer skal have samme længde til elementvis multiplikation.');
    }
    final length = v1.length;
    final result = List<double>.filled(length, 0.0);
    for (var i = 0; i < length; i++) {
      result[i] = v1[i] * v2[i];
    }
    return result;
  }

  /// Giv to vektorer af samme længde, læg dem elementvis sammen og returner en ny vektor.
  static List<double> addElementWise(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) {
      throw ArgumentError('Vektorer skal have samme længde til elementvis addition.');
    }
    final length = v1.length;
    final result = List<double>.filled(length, 0.0);
    for (var i = 0; i < length; i++) {
      result[i] = v1[i] + v2[i];
    }
    return result;
  }

  /// Udregn den gennemsnitlige værdien af en vektor.
  static double mean(List<double> vector) {
    if (vector.isEmpty) return 0.0;
    return sumVector(vector) / vector.length;
  }
}
