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
