// lib/models/light_data_model.dart

import 'package:intl/intl.dart';

class LightData {
  final DateTime capturedAt;
  final int melanopicEdi;
  final int illuminance;
  final String lightType;
  final double exposureScore;
  final bool actionRequired;
  double get ediLux => melanopicEdi.toDouble();
  DateTime get timestamp => capturedAt;

  double get calculatedScore {
    final hourUtc = capturedAt.hour;

    if (hourUtc >= 7 && hourUtc <= 19) {
      return (melanopicEdi / 250).clamp(0.0, 1.0);
    } else if (hourUtc > 19 && hourUtc <= 23) {
      return (melanopicEdi / 10).clamp(0.0, 1.0);
    } else {
      return (melanopicEdi / 1).clamp(0.0, 1.0);
    }
  }

  // Beregner gennemsnits‐score over en liste af LightData‐objekter.
  static double averageScore(List<LightData> data) {
    if (data.isEmpty) return 0.0;
    final total = data.map((d) => d.calculatedScore).reduce((a, b) => a + b);
    return total / data.length;
  }

  // Gennemsnitlig score for en given ugedag (1=mandag .. 7=søndag).
  static double weekdayAverage(List<LightData> data, int weekday) {
    final filtered = data.where((d) => d.timestamp.weekday == weekday).toList();
    return averageScore(filtered);
  }

  // Gennemsnitlig score for en given dag i måneden (baseret på 'dd').
  static double dayAverage(List<LightData> data, String dayKey) {
    final filtered = data
        .where((d) => DateFormat('dd').format(d.timestamp) == dayKey)
        .toList();
    return averageScore(filtered);
  }

  LightData({
    required this.capturedAt,
    required this.melanopicEdi,
    required this.illuminance,
    required this.lightType,
    required this.exposureScore,
    required this.actionRequired,
  });

  // JSON‐parser som sikrer, at “captured_at” altid bliver tolket som UTC.
  factory LightData.fromJson(Map<String, dynamic> json) {
    // 1) Hent den rå streng, "2025-06-05T00:00:03" eller "2025-06-05T00:00:03Z"
    final rawDate = json['captured_at'] as String;

    // 2) Parse den ISO‐8601‐streng som UTC
    final DateTime parsedUtc = DateTime.parse(rawDate);

    // 3) Konverter fragten fra UTC ind i lokal tid (Copenhagen),
    final DateTime local = parsedUtc.toLocal();

    // 4) Melanopic EDI (kan være num eller null)
    final dynamic ediRaw = json['melanopic_edi'];
    final int melanopicEdi = (ediRaw is num) ? ediRaw.toInt() : 0;

    // 5) Illuminance (kan være num eller null)
    final dynamic illumRaw = json['illuminance'];
    final int illuminance = (illumRaw is num) ? illumRaw.toInt() : 0;

    // 6) Exposure score (kan være num eller null)
    final dynamic exposureRaw = json['exposure_score'];
    final double exposureScore =
    (exposureRaw is num) ? exposureRaw.toDouble() : 0.0;

    // 7) Action required (kan nu være bool eller num (0/1))
    final dynamic actionRaw = json['action_required'];
    bool actionRequired;
    if (actionRaw is bool) {
      actionRequired = actionRaw;
    } else if (actionRaw is num) {
      actionRequired = (actionRaw.toInt() == 1);
    } else {
      actionRequired = false;
    }

    // 8) Light type (kan være null eller streng)
    final String lightType = (json['light_type'] as String?) ?? 'Ukendt';

    return LightData(
      capturedAt: local,
      melanopicEdi: melanopicEdi,
      illuminance: illuminance,
      lightType: lightType,
      exposureScore: exposureScore,
      actionRequired: actionRequired,
    );
  }
}
