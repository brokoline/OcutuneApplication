// lib/models/daily_light_summary_model.dart

class DailyLightSummary {
  final DateTime day;
  final int countHighLight;
  final int countLowLight;
  final int totalMeasurements;

  DailyLightSummary({
    required this.day,
    required this.countHighLight,
    required this.countLowLight,
    required this.totalMeasurements,
  });

  factory DailyLightSummary.fromJson(Map<String, dynamic> json) {
    return DailyLightSummary(
      day: DateTime.parse(json['day'] as String),
      countHighLight: (json['count_high_light'] as num).toInt(),
      countLowLight: (json['count_low_light'] as num).toInt(),
      totalMeasurements: (json['total_measurements'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.toIso8601String().split('T').first, // kun “yyyy-MM-dd”
      'count_high_light': countHighLight,
      'count_low_light': countLowLight,
      'total_measurements': totalMeasurements,
    };
  }
}
