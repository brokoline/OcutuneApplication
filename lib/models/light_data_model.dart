import 'package:intl/intl.dart';

class LightData {
  final DateTime capturedAt;
  final int melanopicEdi;
  final int illuminance;
  final String lightType;
  final double exposureScore;
  final bool actionRequired;

  // 👇 Tilføjede getters her
  DateTime get timestamp => capturedAt;
  double get ediLux => melanopicEdi.toDouble();

  // ✅ Beregnet score baseret på tidspunkt og melanopic værdi
  double get calculatedScore {
    final hour = capturedAt.hour;

    if (hour >= 7 && hour <= 19) {
      return (melanopicEdi / 250).clamp(0.0, 1.0);
    } else if (hour > 19 && hour <= 23) {
      return (melanopicEdi / 10).clamp(0.0, 1.0);
    } else {
      return (melanopicEdi / 1).clamp(0.0, 1.0);
    }
  }

  /// 📊 Anvendes til gennemsnitsberegning over en samling af LightData
  static double averageScore(List<LightData> data) {
    if (data.isEmpty) return 0.0;
    final total = data.map((d) => d.calculatedScore).reduce((a, b) => a + b);
    return total / data.length;
  }

  /// 📈 Gennemsnit for en bestemt ugedag (1=mandag, ..., 7=søndag)
  static double weekdayAverage(List<LightData> data, int weekday) {
    final filtered = data.where((d) => d.timestamp.weekday == weekday).toList();
    return averageScore(filtered);
  }

  /// 📆 Gennemsnit for en specifik dato (baseret på dag i måneden som 'dd')
  static double dayAverage(List<LightData> data, String dayKey) {
    final filtered = data.where((d) => DateFormat('dd').format(d.timestamp) == dayKey).toList();
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

  factory LightData.fromJson(Map<String, dynamic> json) {
    final rawDate = json['captured_at'];
    final cleaned = rawDate.replaceAll(' GMT', '');
    final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');

    return LightData(
      capturedAt: formatter.parse(cleaned),
      melanopicEdi: json['melanopic_edi'],
      illuminance: json['illuminance'],
      lightType: json['light_type'] ?? 'Ukendt',
      exposureScore: (json['exposure_score'] ?? 0).toDouble(),
      actionRequired: (json['action_required'] ?? 0) == 1,
    );
  }
}
