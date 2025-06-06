// lib/controller/chronotype_controller.dart

import 'dart:math';

/// ChronotypeManager tager rMEQ (kortversion) som input og
/// estimerer en MEQ (langversion), DLMO‐tid, døgnlængde (tau)
/// samt beregner anbefalede light‐boost‐tider. 
///
/// Du bruger den typisk sådan:
///   final chrono = ChronotypeManager(rmeqScoreAsInt);
///   final label = chrono.getChronotypeLabel();
///   final times = chrono.getRecommendedTimes();
///
/// Hvis der kun er rMEQ (fem‐spørgsmåls‐score), estimeres en
/// tilsvarende MEQ (19‐spørgsmåls‐score) internt i `_estimateMEQ()`.
///
class ChronotypeManager {
  final int totalScore;

  late final double meqScore;
  late final double dlmoHour;
  late final double tau;
  late final double lightboostStartHour;
  late final double lightboostEndHour;

  ChronotypeManager(this.totalScore) {
    meqScore = _estimateMEQ(totalScore);
    dlmoHour = _estimateDlmo(meqScore);
    tau = _estimateTau(meqScore);
    lightboostStartHour = _calculateLightboostStart(tau, dlmoHour);
    lightboostEndHour = lightboostStartHour + 1.5; // eksempel: 1.5 timers boost
  }

  /// Returnerer en tekst‐label baseret på rMEQ‐score
  String getChronotypeLabel() {
    if (totalScore >= 22) return 'definitely_morning';
    if (totalScore >= 18) return 'moderately_morning';
    if (totalScore >= 12) return 'neither';
    if (totalScore >= 8)  return 'moderately_evening';
    return 'definitely_evening';
  }

  /// Simpel lineær interpolation fra rMEQ (5 spørgsmål) til MEQ (19 spørgsmål).
  /// Du kan justere disse return‐værdier, så de matcher jeres egne data/model.
  double _estimateMEQ(int rmeq) {
    switch (getChronotypeLabel()) {
      case 'definitely_morning':
        return 80;
      case 'moderately_morning':
        return 65;
      case 'neither':
        return 50;
      case 'moderately_evening':
        return 35;
      case 'definitely_evening':
        return 25;
      default:
        return 50;
    }
  }

  /// Approksimerer DLMO‐tidspunkt (i timer) ud fra meqScore.
  double _estimateDlmo(double meq) {
    // Eksempel‐formel baseret på publicerede studier:
    return (209.0 - meq) / 7.29;
  }

  /// Approksimerer døgnlængde (tau) ud fra meqScore.
  double _estimateTau(double meq) {
    return (24.98 - meq) / 0.0171;
  }

  /// Beregner start‐tidspunkt (i timer) for “light boost” relativt til DLMO.
  double _calculateLightboostStart(double tau, double dlmo) {
    final double phaseShift = 24 - tau;
    final double hoursBeforeDlmo = 2.6 + 0.0667 * sqrt(9111 + 15000 * phaseShift);
    return dlmo - hoursBeforeDlmo;
  }

  /// Returnerer en Map med anbefalede tidspunkter (“dlmo”, “sleep_start” osv.)
  /// i form af DateTime‐objekter for den givne dag.
  Map<String, DateTime> getRecommendedTimes({DateTime? reference}) {
    final now = reference ?? DateTime.now();

    DateTime _timeFromDouble(double hour) {
      final int h = hour.floor();
      final int m = ((hour % 1) * 60).round();
      return DateTime(now.year, now.month, now.day, h, m);
    }

    return {
      'dlmo': _timeFromDouble(dlmoHour),
      'sleep_start': _timeFromDouble(dlmoHour + 2),
      'wake_time': _timeFromDouble(dlmoHour + 10),
      'lightboost_start': _timeFromDouble(lightboostStartHour),
      'lightboost_end': _timeFromDouble(lightboostEndHour),
    };
  }
}
