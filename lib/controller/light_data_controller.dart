// lib/controllers/light_data_controller.dart

import 'dart:async';


import '../services/processing/recommendation_calculator.dart';
import '../services/services/api_services.dart';
import '../utils/light_utils.dart';

/// Controller der henter lysdata, beregner CDF‐perioder og udsender et snapshot.
class LightDataController {
  final String patientId;
  final int    rmeqScore;      // Husk nu at give rMEQ‐scoren ind
  final _rc = RecommendationCalculator();

  final StreamController<LightDataSnapshot> _snapController =
  StreamController<LightDataSnapshot>.broadcast();
  Stream<LightDataSnapshot> get snapshotStream => _snapController.stream;

  Timer? _timer;

  LightDataController({
    required this.patientId,
    required this.rmeqScore,
  }) {
    _fetchAndEmit();
    _timer = Timer.periodic(Duration(minutes: 5), (_) => _fetchAndEmit());
  }

  Future<void> _fetchAndEmit() async {
    // 1) Hent rå data fra API
    final data = await ApiService.fetchDailyLightData(patientId: patientId);

    // 2) Filtrer til i dag
    final now   = DateTime.now();
    final today = data.where((d) =>
    d.capturedAt.toLocal().year  == now.year  &&
        d.capturedAt.toLocal().month == now.month &&
        d.capturedAt.toLocal().day   == now.day
    ).toList();

    // 3) Dag‐bucketing
    final hourlyLux = LightUtils.groupByHourOfDay(today);

    // 4) CDF‐beregninger
    final meq        = _rc.convertToMEQ(rmeqScore);
    final dlmo       = _rc.approxDLMO(meq);
    final tau        = _rc.approxTau(meq);
    final boostStart = _rc.phaseShift(tau, dlmo);
    final boostEnd   = boostStart + 1.5;   // f.eks. 1½ times boost
    final sleepStart = dlmo + 2;           // f.eks. 2 timer efter DLMO
    final sleepEnd   = sleepStart + 8;     // 8 timers søvn

    // 5) Udlad snapshot
    _snapController.add(LightDataSnapshot(
      hourlyLux:  hourlyLux,
      dlmo:       dlmo,
      boostStart: boostStart,
      boostEnd:   boostEnd,
      sleepStart: sleepStart,
      sleepEnd:   sleepEnd,
      timestamp:  now,
    ));
  }

  void dispose() {
    _timer?.cancel();
    _snapController.close();
  }
}

/// Data‐POJO til UI
class LightDataSnapshot {
  final List<double> hourlyLux;
  final double dlmo, boostStart, boostEnd, sleepStart, sleepEnd;
  final DateTime timestamp;

  LightDataSnapshot({
    required this.hourlyLux,
    required this.dlmo,
    required this.boostStart,
    required this.boostEnd,
    required this.sleepStart,
    required this.sleepEnd,
    required this.timestamp,
  });
}
