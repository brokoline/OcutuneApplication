// lib/services/recommendation_service.dart

import 'dart:math';

/// RecommendationCalculator håndterer alle cirkadiske beregninger:
/// - Konvertering rMEQ → MEQ
/// - Estimat af DLMO (melatonin onset)
/// - Beregning af τ (fri kørsel)
/// - Beregning af phase shift (boostStart)
class RecommendationCalculator {
  /// Parameterløs standardkonstruktør
  RecommendationCalculator();

  /// 1) Konverter rMEQ‐score (4–25) til MEQ‐score (16–86) ved lineær interpolation
  /// baseret på Table 4.1 :contentReference[oaicite:0]{index=0}.
  double convertToMEQ(int rmeqScore) {
    const double minRMEQ = 4, maxRMEQ = 25;
    const double minMEQ  = 16, maxMEQ  = 86;
    final slope = (maxMEQ - minMEQ) / (maxRMEQ - minRMEQ);
    return minMEQ + slope * (rmeqScore - minRMEQ);
  }

  /// 2) Beregn DLMO (timer siden midnat) ved at isolere DLMO i
  ///     MEQ = 209.023 − 7.288·DLMO  ⇒  DLMO = (209.023 − MEQ)/7.288 :contentReference[oaicite:1]{index=1}
  double approxDLMO(double meq) {
    final dlmo = (209.023 - meq) / 7.288;
    // Hvis DLMO < 0 (før midnat), ryk til næste dag
    return dlmo < 0 ? dlmo + 24 : dlmo;
  }

  /// 3) Beregn τ (fri kørsel i timer) ved at isolere τ i
  ///    MEQ = 24.97514314 − 0.01714266123·τ  ⇒  τ = (24.97514314 − MEQ)/0.01714266123 :contentReference[oaicite:2]{index=2}
  double approxTau(double meq) {
    return (24.97514314 - meq) / 0.01714266123;
  }

  /// 4) Beregn start‐tidspunktet for light‐boost (timer siden midnat)
  /// ved at bruge phase shift‐formlen:
  ///   boostRelativeToDLMO = 2.600000000 + 0.06666666667*√(9111 + 15000·(τ−24))
  ///   start = DLMO − boostRelativeToDLMO :contentReference[oaicite:3]{index=3}
  double phaseShift(double tau, double dlmo) {
    final shift = tau - 24;
    final boostRelativeToDLMO = 2.600000000
        + 0.06666666667 * sqrt(9111 + 15000 * shift);
    return dlmo - boostRelativeToDLMO;
  }
}
