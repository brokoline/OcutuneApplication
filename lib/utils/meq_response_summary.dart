import '../services/services/customer_data_service.dart';

class MeqResponseSummary {
  final int rmeq;
  final int? meq;

  MeqResponseSummary({
    required this.rmeq,
    required this.meq,
  });

  factory MeqResponseSummary.fromGlobal() {
    final resp = currentCustomerResponse;
    return MeqResponseSummary(
      rmeq: resp?.rmeqScore ?? 0,
      meq:  resp?.meqScore,
    );
  }

  String get meqDisplay => meq?.toString() ?? '';
}
