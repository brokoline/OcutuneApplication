import 'dart:math';

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
    lightboostEndHour = lightboostStartHour + 2;
  }

  // Returnerer en tekst‐label baseret på rMEQ‐score
  String getChronotypeLabel() {
    if (totalScore >= 22) return 'definitely_morning';
    if (totalScore >= 18) return 'moderately_morning';
    if (totalScore >= 12) return 'neither';
    if (totalScore >= 8)  return 'moderately_evening';
    return 'definitely_evening';
  }

  double _estimateMEQ(int rmeq) {
    switch (getChronotypeLabel()) {
      case 'definitely_morning':
        return 78;
      case 'moderately_morning':
        return 64;
      case 'intermediate':
        return 50;
      case 'moderately_evening':
        return 36;
      case 'definitely_evening':
        return 23;
      default:
        return 50;
    }
  }

  double _estimateDlmo(double meq) {
    // Eksempel‐formel baseret på publicerede studier:
    return (209.0 - meq) / 7.29;
  }

  // Approksimerer døgnlængde (tau) ud fra meqScore.
  double _estimateTau(double meq) {
    return (24.98 - meq) / 0.0171;
  }

  // Beregner start‐tidspunkt (i timer) for “light boost” relativt til DLMO.
  double _calculateLightboostStart(double tau, double dlmo) {
    final double phaseShift = 24 - tau;
    final double hoursBeforeDlmo = 2.6 + 0.0667 * sqrt(9111 + 15000 * phaseShift);
    return dlmo - hoursBeforeDlmo;
  }

  // Returnerer en Map med anbefalede tidspunkter (“dlmo”, “sleep_start” osv.)
  // i form af DateTime‐objekter for den givne dag.
  Map<String, DateTime> getRecommendedTimes({DateTime? reference}) {
    final now = reference ?? DateTime.now();

    DateTime timeFromDouble(double hour) {
      final int h = hour.floor();
      final int m = ((hour % 1) * 60).round();
      return DateTime(now.year, now.month, now.day, h, m);
    }

    return {
      'dlmo': timeFromDouble(dlmoHour),
      'sleep_start': timeFromDouble(dlmoHour + 2),
      'wake_time': timeFromDouble(dlmoHour + 10),
      'lightboost_start': timeFromDouble(lightboostStartHour),
      'lightboost_end': timeFromDouble(lightboostEndHour),
    };
  }
}
