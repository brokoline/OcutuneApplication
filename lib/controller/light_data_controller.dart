// lib/controllers/light_data_controller.dart

import 'dart:async';
import 'package:ocutune_light_logger/services/processing/recommendation_calculator.dart';
import 'package:ocutune_light_logger/utils/light_utils.dart';

import '../services/services/api_services.dart';

/// Henter dagslysdata, beregner CDF-perioder og udsender et snapshot til UI.
class LightDataController {
  final String patientId;
  final int    rmeqScore;
  final RecommendationCalculator _rc;

  final StreamController<LightDataSnapshot> _snapController =
  StreamController<LightDataSnapshot>.broadcast();
  Stream<LightDataSnapshot> get snapshotStream => _snapController.stream;

  Timer? _timer;

  LightDataController({
    required this.patientId,
    required this.rmeqScore,
  }) : _rc = RecommendationCalculator(rmeqScore) {
    _fetchAndEmit();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchAndEmit());
  }

  Future<void> _fetchAndEmit() async {
    // 1) Hent alle lys‐målinger for patienten
    final allData = await ApiService.fetchDailyLightData(patientId: patientId);

    // 2) Filtrér til i dag
    final now   = DateTime.now();
    final today = allData.where((d) {
      final local = d.capturedAt.toLocal();
      return local.year  == now.year &&
          local.month == now.month &&
          local.day   == now.day;
    }).toList();

    // 3) Dag‐bucketing: List<double> med 24 timer
    final hourlyLux = LightUtils.groupByHourOfDay(today);

    // 4) Beregn CDF‐tidspunkter
    final times = _rc.getRecommendedTimes();

    // 5) Omdan DateTime → double timer siden midnat
    double _toHours(DateTime dt) => dt.hour + dt.minute / 60.0;

    final dlmo           = _toHours(times['dlmo']!);
    final lightboostStart= _toHours(times['lightboost_start']!);
    final lightboostEnd  = _toHours(times['lightboost_end']!);
    final sleepStart     = _toHours(times['sleep_start']!);
    final sleepEnd       = _toHours(times['wake_time']!);

    // 6) Send snapshot ud
    _snapController.add(LightDataSnapshot(
      hourlyLux:       hourlyLux,
      dlmo:            dlmo,
      lightboostStart: lightboostStart,
      lightboostEnd:   lightboostEnd,
      sleepStart:      sleepStart,
      sleepEnd:        sleepEnd,
      timestamp:       now,
    ));
  }

  void dispose() {
    _timer?.cancel();
    _snapController.close();
  }
}

/// Data‐POJO til UI‐widget’en
class LightDataSnapshot {
  final List<double> hourlyLux;
  final double       dlmo;
  final double       lightboostStart;
  final double       lightboostEnd;
  final double       sleepStart;
  final double       sleepEnd;
  final DateTime     timestamp;

  LightDataSnapshot({
    required this.hourlyLux,
    required this.dlmo,
    required this.lightboostStart,
    required this.lightboostEnd,
    required this.sleepStart,
    required this.sleepEnd,
    required this.timestamp,
  });
}
