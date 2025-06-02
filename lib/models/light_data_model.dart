// lib/models/light_data_model.dart

import 'package:intl/intl.dart';

class LightData {
  /// Her gemmer vi UTC‐timestampet præcist som modtaget fra serveren.
  final DateTime capturedAt;

  /// Det melanopiske EDI‐tal (int), som vi efterfølgende kan omsætte til double.
  final int melanopicEdi;

  /// Illuminance (lux), hvis du ønsker at bruge dét i andre beregninger.
  final int illuminance;

  /// Typen af lys (fx “natural”, “artificial” eller “Ukendt”).
  final String lightType;

  /// En eventuel score, der allerede ligger i JSON‐payloaden.
  final double exposureScore;

  /// Om serveren har flagget, at der kræves en handling.
  final bool actionRequired;

  /// Ekstra getter, hvis du vil tilgå melanopicEdi som double.
  double get ediLux => melanopicEdi.toDouble();

  /// Alias for capturedAt (UTC).
  DateTime get timestamp => capturedAt;

  /// Et eksempel på en beregna­tion baseret på “capturedAt.hour” i UTC.
  /// Hvis du i stedet vil beregne udfra lokal tid, kan du ændre
  /// til “capturedAt.toLocal().hour”.
  double get calculatedScore {
    final hourUtc = capturedAt.hour;

    // Eksempel‐logik (tilpas eventuelt jeres egne regler)
    if (hourUtc >= 7 && hourUtc <= 19) {
      return (melanopicEdi / 250).clamp(0.0, 1.0);
    } else if (hourUtc > 19 && hourUtc <= 23) {
      return (melanopicEdi / 10).clamp(0.0, 1.0);
    } else {
      return (melanopicEdi / 1).clamp(0.0, 1.0);
    }
  }

  /// Beregner gennemsnits‐score over en liste af LightData‐objekter.
  static double averageScore(List<LightData> data) {
    if (data.isEmpty) return 0.0;
    final total = data.map((d) => d.calculatedScore).reduce((a, b) => a + b);
    return total / data.length;
  }

  /// Gennemsnitlig score for en given ugedag (1=mandag .. 7=søndag).
  static double weekdayAverage(List<LightData> data, int weekday) {
    final filtered = data.where((d) => d.timestamp.weekday == weekday).toList();
    return averageScore(filtered);
  }

  /// Gennemsnitlig score for en given dag i måneden (baseret på 'dd').
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

  /// JSON‐parser som sikrer, at “captured_at” altid bliver tolket som UTC.
  factory LightData.fromJson(Map<String, dynamic> json) {
    // 1) Hent den rå streng, fx: "Tue, 02 Jun 2025 08:15:00 GMT"
    final rawDate = json['captured_at'] as String;

    // 2) Fjern " GMT" (hvis serveren inkluderer det – ellers kan du udelade denne linje)
    final cleaned = rawDate.replaceAll(' GMT', '');

    // 3) Opsæt formatter, der matcher "Tue, 02 Jun 2025 08:15:00"
    final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');

    // 4) Parse streng som UTC ved at sætte `isUtc=true`.
    //    Dette sikrer, at den streng, vi får, bliver et DateTime med isUtc==true.
    final DateTime parsedUtc = formatter.parse(cleaned, true);

    return LightData(
      capturedAt: parsedUtc,
      melanopicEdi: (json['melanopic_edi'] as num).toInt(),
      illuminance: (json['illuminance'] as num).toInt(),
      lightType: json['light_type'] as String? ?? 'Ukendt',
      exposureScore: (json['exposure_score'] as num? ?? 0).toDouble(),
      actionRequired: (json['action_required'] as num? ?? 0) == 1,
    );
  }
}
