// lib/models/meq_response_summary.dart

import '../services/services/customer_data_service.dart';

class MeqResponseSummary {
  final int rmeq;
  final int? meq;

  MeqResponseSummary({
    required this.rmeq,
    required this.meq,
  });

  // Henter global state direkte
  factory MeqResponseSummary.fromGlobal() {
    final resp = currentCustomerResponse;
    return MeqResponseSummary(
      rmeq: resp?.rmeqScore ?? 0,
      meq:  resp?.meqScore,
    );
  }

  // Returnerer MEQ som tekst, eller tom streng
  String get meqDisplay => meq?.toString() ?? '';
}
