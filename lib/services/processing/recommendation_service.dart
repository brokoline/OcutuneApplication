
import 'dart:math';

class RecommendationCalculator {
  final int totalScore;

  late final double meqScore;
  late final double dlmoHour;
  late final double tau;
  late final double lightboostStartHour;
  late final double lightboostEndHour;

  RecommendationCalculator(this.totalScore) {
    meqScore = _estimateMEQ(totalScore);
    dlmoHour = _estimateDlmo(meqScore);
    tau = _estimateTau(meqScore);
    lightboostStartHour = _calculateLightboostStart(tau, dlmoHour);
    lightboostEndHour = lightboostStartHour + 1.5;
  }

  /// Giver en tekst-label til chronotypen baseret på score
  String getChronotypeLabel() {
    if (totalScore >= 22) return 'Definitivt morgen-menneske';
    if (totalScore >= 18) return 'Moderat morgen-menneske';
    if (totalScore >= 12) return 'Intermediate';
    if (totalScore >= 8)  return 'Moderat aften-menneske';
    return 'Definitivt aften-menneske';
  }

  /// Omregner rMEQ-score til et estimeret MEQ-score
  double _estimateMEQ(int rmeq) {
    // Lineær interpolation over kendte intervaller
    return switch (getChronotypeLabel()) {
      'Definitivt morgen-menneske'   => 80,
      'Moderat morgen-menneske'   => 65,
      'Intermediate'              => 50,
      'Moderat aften-menneske'   => 35,
      'Definitivt aften-menneske'   => 25,
      _ => 50
    };
  }

  /// Estimerer tidspunkt for DLMO (i timer)
  double _estimateDlmo(double meq) {
    // Approksimation baseret på grafanalyser fra studier
    return (209.0 - meq) / 7.29;
  }

  /// Estimerer døgnlængde (tau)
  double _estimateTau(double meq) {
    return (24.98 - meq) / 0.0171;
  }

  /// Udregner tidspunkt for lightboost-start relativt til DLMO
  double _calculateLightboostStart(double tau, double dlmoHour) {
    double phaseShift = 24 - tau;
    double hoursBeforeDlmo = 2.6 + 0.0667 * sqrt(9111 + 15000 * phaseShift);
    return dlmoHour - hoursBeforeDlmo;
  }

  /// Returnerer tidspunkter som DateTime på aktuel dag
  Map<String, DateTime> getRecommendedTimes({DateTime? reference}) {
    final now = reference ?? DateTime.now();

    DateTime timeFromHour(double hour) {
      int h = hour.floor();
      int m = ((hour % 1) * 60).round();
      return DateTime(now.year, now.month, now.day, h, m);
    }


    return {
      'dlmo': timeFromHour(dlmoHour),
      'sleep_start': timeFromHour(dlmoHour + 2),
      'wake_time': timeFromHour(dlmoHour + 10),
      'lightboost_start': timeFromHour(lightboostStartHour),
      'lightboost_end': timeFromHour(lightboostEndHour),
    };
  }
}
