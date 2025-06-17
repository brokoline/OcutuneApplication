import '../services/services/customer_data_service.dart';

// Et lille objekt, der pakker rMEQ og MEQ sammen.
// MEQ kan være `null` indtil den er beregnet; `meqDisplay` giver en tom streng i så fald.
class meqResponseSummary {
  final int rmeq;
  final int? meq;

  meqResponseSummary({
    required this.rmeq,
    required this.meq,
  });

  factory meqResponseSummary.fromGlobal() {
    final resp = currentCustomerResponse;
    return meqResponseSummary(
      rmeq: resp?.rmeqScore ?? 0,
      meq:  resp?.meqScore,
    );
  }

  /// Returnerer MEQ som tekst, eller tom streng hvis ikke sat endnu.
  String get meqDisplay => meq?.toString() ?? '';
}
