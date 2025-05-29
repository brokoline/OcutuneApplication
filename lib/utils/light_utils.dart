import 'dart:math';
import '../models/light_data_model.dart';

class LightDataProcessing {
  final int rMEQ;

  LightDataProcessing({required this.rMEQ});

  double convertToMEQ() {
    if (rMEQ >= 22) return 78.0;
    if (rMEQ >= 18) return 64.0;
    if (rMEQ >= 12) return 50.0;
    if (rMEQ >= 8) return 36.0;
    return 23.0;
  }

  double estimateDLMO(double meq) {
    return (209.023 - meq) / 7.288;
  }

  double estimateTau(double meq) {
    return (24.97514314 - meq) / 0.01714266123;
  }

  double calculateBoostStart(double tau, double dlmo) {
    double shift = tau - 24;
    double boostOffset = 2.6 + 0.06666666667 * sqrt(9111 + 15000 * shift);
    return dlmo - boostOffset;
  }

  Map<String, double> getTimeWindows() {
    final meq = convertToMEQ();
    final dlmo = estimateDLMO(meq);
    final tau = estimateTau(meq);
    final boostStart = calculateBoostStart(tau, dlmo);
    final boostEnd = boostStart + 1.5;
    final sleepStart = dlmo + 2.0;
    final sleepEnd = dlmo + 10.0;

    return {
      'dlmoStart': dlmo,
      'dlmoEnd': dlmo + 2.0,
      'sleepStart': sleepStart,
      'sleepEnd': sleepEnd,
      'boostStart': boostStart,
      'boostEnd': boostEnd
    };
  }

  String getCurrentInterval(DateTime now) {
    final time = now.hour + now.minute / 60.0;
    final windows = getTimeWindows();

    bool isIn(double start, double end) {
      return start < end
          ? time >= start && time < end
          : time >= start || time < end;
    }

    if (isIn(windows['boostStart']!, windows['boostEnd']!)) return 'lightboost';
    if (isIn(windows['dlmoStart']!, windows['dlmoEnd']!)) return 'dlmo';
    if (isIn(windows['sleepStart']!, windows['sleepEnd']!)) return 'sleep';
    return 'daytime';
  }

  double calculateLightScore(double melanopicEDI, String interval) {
    switch (interval) {
      case 'lightboost':
        return (melanopicEDI / 1316).clamp(0.0, 1.0) * 100;
      case 'daytime':
        return (melanopicEDI / 250).clamp(0.0, 1.0) * 100;
      case 'dlmo':
        if (melanopicEDI <= 0.0) return 100.0;
        return (10 / melanopicEDI).clamp(0.0, 1.0) * 100;
      case 'sleep':
        if (melanopicEDI <= 0.0) return 100.0;
        return (1 / melanopicEDI).clamp(0.0, 1.0) * 100;
      default:
        return 0.0;
    }
  }

  Map<String, dynamic> evaluateLightExposure({
    required double melanopicEDI,
    DateTime? time
  }) {
    final now = time ?? DateTime.now();
    final interval = getCurrentInterval(now);
    final score = calculateLightScore(melanopicEDI, interval);

    final String recommendation;
    if (score == 100.0) {
      recommendation = "Ingen handling nødvendig";
    } else if (interval == 'dlmo' || interval == 'sleep') {
      recommendation = "Reducer lysniveauet";
    } else {
      recommendation = "Øg lysniveauet";
    }

    return {
      'score': score,
      'interval': interval,
      'recommendation': recommendation
    };
  }

  List<String> generateAdvancedRecommendations({
    required List<LightData> data,
    required int rMEQ
  }) {
    final processor = LightDataProcessing(rMEQ: rMEQ);
    final Map<String, int> counters = {
      'lowMorning': 0,
      'highEvening': 0,
      'poorScore': 0
    };

    for (final d in data) {
      final eval = processor.evaluateLightExposure(
          melanopicEDI: d.melanopicEdi.toDouble(),
          time: d.capturedAt
      );

      if (d.capturedAt.hour >= 6 &&
          d.capturedAt.hour <= 10 &&
          eval['score'] < 60) {
        counters['lowMorning'] = counters['lowMorning']! + 1;
      }

      if (d.capturedAt.hour >= 20 &&
          eval['interval'] == 'sleep' &&
          eval['score'] < 60) {
        counters['highEvening'] = counters['highEvening']! + 1;
      }

      if (eval['score'] < 50) {
        counters['poorScore'] = counters['poorScore']! + 1;
      }
    }

    final List<String> messages = [];

    if (counters['lowMorning']! > 3) {
      messages.add("Patienten har haft lav lys-eksponering i morgentimerne – anbefal at gå udenfor tidligere.");
    }

    if (counters['highEvening']! > 2) {
      messages.add("Patienten har haft for meget lys om aftenen – anbefal at dæmp belysningen efter kl. 20.");
    }

    if (counters['poorScore']! > 5) {
      messages.add("Flere målinger viser utilstrækkeligt lys – overvej en snak med patienten om at justere sine rutiner.");
    }

    if (messages.isEmpty) {
      messages.add("Patientens lysrytme ser fin ud i denne periode");
    }

    return messages;
  }

  Map<int, double> groupLuxByDay(List<LightData> data) {
    final Map<int, List<double>> map = {};
    for (final d in data) {
      final weekday = d.timestamp.weekday;
      map.putIfAbsent(weekday, () => []).add(d.ediLux);
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  Map<String, double> groupLuxByWeekdayName(List<LightData> data) {
    final Map<String, double> luxPerDay = {
      'Man': 0,
      'Tir': 0,
      'Ons': 0,
      'Tor': 0,
      'Fre': 0,
      'Lør': 0,
      'Søn': 0,
    };

    for (final d in data) {
      final weekday = d.timestamp.weekday;
      final names = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];
      final name = names[weekday - 1];
      if (luxPerDay.containsKey(name)) {
        luxPerDay[name] = luxPerDay[name]! + d.illuminance;
      }
    }

    return luxPerDay;
  }
}