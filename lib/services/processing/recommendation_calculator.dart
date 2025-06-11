import 'dart:math';

/// Recom­mendationCalculator håndterer alle CDF-beregninger fra rMEQ → anbefalede tidspunkter.
class RecommendationCalculator {
  final int totalScore;

  late final double meqScore;
  late final double dlmoHour;
  late final double tau;
  late final double lightboostStartHour;
  late final double lightboostEndHour;

  RecommendationCalculator(this.totalScore) {
    meqScore            = _estimateMEQ(totalScore);
    dlmoHour            = _estimateDlmo(meqScore);
    tau                 = _estimateTau(meqScore);
    lightboostStartHour = _calculateLightboostStart(tau, dlmoHour);
    lightboostEndHour   = lightboostStartHour + 1.5;
  }

  /// Tekst‐label for chronotype baseret på totalScore (rMEQ).
  String getChronotypeLabel() {
    if (totalScore >= 22) return 'Definitivt morgen-menneske';
    if (totalScore >= 18) return 'Moderat morgen-menneske';
    if (totalScore >= 12) return 'Intermediate';
    if (totalScore >= 8)  return 'Moderat aften-menneske';
    return 'Definitivt aften-menneske';
  }

  /// rMEQ (4–25) → MEQ estimeret via faste trin.
  double _estimateMEQ(int rmeq) {
    return switch (getChronotypeLabel()) {
      'Definitivt morgen-menneske'   => 80,
      'Moderat morgen-menneske'       => 65,
      'Intermediate'                  => 50,
      'Moderat aften-menneske'        => 35,
      'Definitivt aften-menneske'     => 25,
      _                                => 50,
    };
  }

  /// Estimerer DLMO i timer siden midnat: (209 − MEQ)/7.29
  double _estimateDlmo(double meq) {
    final dlmo = (209.0 - meq) / 7.29;
    return dlmo < 0 ? dlmo + 24 : dlmo;
  }

  /// Estimerer τ (fri kørsel) i timer: (24.98 − MEQ)/0.0171
  double _estimateTau(double meq) {
    return (24.98 - meq) / 0.0171;
  }

  /// Udregner starttidspunkt for light-boost relativt til DLMO
  double _calculateLightboostStart(double tau, double dlmoHour) {
    final phaseShift = 24 - tau;
    final hoursBeforeDlmo =
        2.6 + 0.0667 * sqrt(9111 + 15000 * phaseShift);
    return dlmoHour - hoursBeforeDlmo;
  }

  /// Returnerer anbefalede tidspunkter som DateTime på samme dato som [reference].
  Map<String, DateTime> getRecommendedTimes({DateTime? reference}) {
    final now = reference ?? DateTime.now();

    DateTime timeFromHour(double hour) {
      final h = hour.floor();
      final m = ((hour - h) * 60).round();
      return DateTime(now.year, now.month, now.day, h, m);
    }

    return {
      'dlmo':             timeFromHour(dlmoHour),
      'sleep_start':      timeFromHour(dlmoHour + 2),
      'wake_time':        timeFromHour(dlmoHour + 10),
      'lightboost_start': timeFromHour(lightboostStartHour),
      'lightboost_end':   timeFromHour(lightboostEndHour),
    };
  }
}
